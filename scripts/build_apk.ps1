<#
.SYNOPSIS
    Builds the Set El Kol debug APK with full verification and automated checks.
.DESCRIPTION
    Runs:
      1. Environment & SDK availability checks (Flutter & Android SDK).
      2. flutter pub get
      3. dart format --output=none --set-exit-if-changed lib (formatting check)
      4. flutter analyze
      5. flutter build apk --debug
      6. Output artifact verification (build\app\outputs\flutter-apk\app-debug.apk)
.NOTES
    Saves build output and step logs to: build\build.log
    Prevents concurrent executions using build\.build.lock
#>

[CmdletBinding()]
param(
    [ValidateSet("release", "debug", "both")]
    [string]$Mode = "release",
    [switch]$SkipFormatCheck
)

# Ensure working directory is the Flutter project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$buildDir = Join-Path $projectRoot "build"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

$logFile = Join-Path $buildDir "build.log"
$lockFile = Join-Path $buildDir ".build.lock"

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formatted = "[$timestamp] [$Level] $Message"
    Write-Host $formatted
    Add-Content -Path $logFile -Value $formatted -Encoding UTF8
}

function Run-StepCommand {
    param(
        [string]$Description,
        [string]$Executable,
        [string[]]$Arguments
    )

    Log-Message "Executing: $Executable $($Arguments -join ' ')" "INFO"
    
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $Executable
    $pinfo.Arguments = ($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.WorkingDirectory = $projectRoot

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo

    $outputBuilder = New-Object System.Text.StringBuilder
    $errorBuilder = New-Object System.Text.StringBuilder

    $outHandler = {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $outputBuilder.AppendLine($EventArgs.Data) | Out-Null
        }
    }
    $errHandler = {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $errorBuilder.AppendLine($EventArgs.Data) | Out-Null
        }
    }

    Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outHandler | Out-Null
    Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errHandler | Out-Null

    [void]$process.Start()
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    $process.WaitForExit()
    $exitCode = $process.ExitCode

    $outText = $outputBuilder.ToString().Trim()
    $errText = $errorBuilder.ToString().Trim()

    if ($outText) {
        Add-Content -Path $logFile -Value $outText -Encoding UTF8
    }
    if ($errText) {
        Add-Content -Path $logFile -Value "[STDERR] $errText" -Encoding UTF8
    }

    if ($exitCode -ne 0) {
        Log-Message "$Description failed with exit code $exitCode." "ERROR"
        if ($errText) {
            Log-Message "Error output: $errText" "ERROR"
        }
        return $false
    }

    return $true
}

# -------------------------------------------------------------
# 0. Concurrency Guard / Lockfile Check
# -------------------------------------------------------------
if (Test-Path $lockFile) {
    $existingPid = Get-Content $lockFile -ErrorAction SilentlyContinue
    $runningProcess = $null
    if ($existingPid -match '^\d+$') {
        $runningProcess = Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue
    }
    if ($runningProcess) {
        Log-Message "A build is already in progress (PID $existingPid). Skipping trigger to prevent simultaneous builds." "WARN"
        exit 0
    } else {
        Log-Message "Found stale lock file from previous process. Removing stale lock." "INFO"
        Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    }
}

# Create lockfile with current PID
$PID | Out-File -FilePath $lockFile -Encoding ASCII -Force

# Register clean-up on exit
$cleanUp = {
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
}

try {
    "============================================================" | Out-File $logFile -Encoding UTF8 -Append
    Log-Message "Starting Set El Kol APK Debug Build Workflow..." "INFO"
    Log-Message "Project Root: $projectRoot" "INFO"

    # ---------------------------------------------------------
    # 1. Environment & SDK Verification
    # ---------------------------------------------------------
    Log-Message "Step 1/5: Verifying Flutter & Android SDK environment..." "INFO"

    $flutterBin = $null
    if (Test-Path "D:\flutter\bin\flutter.bat") {
        $flutterBin = "D:\flutter\bin\flutter.bat"
    } elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
        $flutterBin = (Get-Command flutter).Source
    } elseif (Test-Path "C:\flutter\bin\flutter.bat") {
        $flutterBin = "C:\flutter\bin\flutter.bat"
    }

    if (-not $flutterBin) {
        Log-Message "Flutter executable not found in PATH or standard installation directories." "ERROR"
        exit 1
    }

    $flutterDir = Split-Path -Parent $flutterBin
    $dartBin = Join-Path $flutterDir "dart.bat"
    if (-not (Test-Path $dartBin)) {
        if (Get-Command dart -ErrorAction SilentlyContinue) {
            $dartBin = (Get-Command dart).Source
        } else {
            $dartBin = $flutterBin
        }
    }

    $androidSdk = $env:ANDROID_HOME
    if (-not $androidSdk) {
        $androidSdk = $env:ANDROID_SDK_ROOT
    }
    if (-not $androidSdk) {
        $localProps = Join-Path $projectRoot "android\local.properties"
        if (Test-Path $localProps) {
            $sdkLine = Get-Content $localProps | Where-Object { $_ -match "^sdk\.dir=" } | Select-Object -First 1
            if ($sdkLine) {
                $androidSdk = ($sdkLine -split "=", 2)[1].Trim().Replace("\\", "\")
            }
        }
    }
    if (-not $androidSdk -and (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
        $androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
    }

    if (-not $androidSdk -or -not (Test-Path $androidSdk)) {
        Log-Message "Android SDK not found. Please ensure Android SDK is installed." "ERROR"
        exit 1
    }

    Log-Message "  - Flutter: $flutterBin" "INFO"
    Log-Message "  - Dart:    $dartBin" "INFO"
    Log-Message "  - Android: $androidSdk" "INFO"

    # ---------------------------------------------------------
    # 2. Dependency Resolution (flutter pub get)
    # ---------------------------------------------------------
    Log-Message "Step 2/5: Running 'flutter pub get'..." "INFO"
    $ok = Run-StepCommand "flutter pub get" $flutterBin @("pub", "get")
    if (-not $ok) { exit 1 }
    Log-Message "  [OK] Dependencies resolved successfully." "INFO"

    # ---------------------------------------------------------
    # 3. Formatting Check (dart format --output=none --set-exit-if-changed lib)
    # ---------------------------------------------------------
    Log-Message "Step 3/5: Running formatting check on 'lib'..." "INFO"
    if ($SkipFormatCheck) {
        Log-Message "  [SKIPPED] Formatting check skipped via -SkipFormatCheck flag." "WARN"
    } else {
        $ok = Run-StepCommand "dart format check" $dartBin @("format", "--output=none", "--set-exit-if-changed", "lib")
        if (-not $ok) {
            Log-Message "Formatting check failed! Run 'dart format lib' to resolve formatting." "ERROR"
            exit 1
        }
        Log-Message "  [OK] Formatting check passed cleanly." "INFO"
    }

    # ---------------------------------------------------------
    # 4. Code Analysis (flutter analyze)
    # ---------------------------------------------------------
    Log-Message "Step 4/5: Running 'flutter analyze'..." "INFO"
    $ok = Run-StepCommand "flutter analyze" $flutterBin @("analyze")
    if (-not $ok) {
        Log-Message "Code analysis found issues. Resolve them before building." "ERROR"
        exit 1
    }
    Log-Message "  [OK] 'flutter analyze' passed with 0 issues." "INFO"

    # ---------------------------------------------------------
    # 5. Build APK ($Mode)
    # ---------------------------------------------------------
    $modesToBuild = @()
    if ($Mode -eq "both") {
        $modesToBuild = @("release", "debug")
    } else {
        $modesToBuild = @($Mode)
    }

    $builtArtifacts = @()

    foreach ($currentMode in $modesToBuild) {
        Log-Message "Step 5: Building Android APK in '$currentMode' mode ('flutter build apk --$currentMode')..." "INFO"
        $ok = Run-StepCommand "flutter build apk --$currentMode" $flutterBin @("build", "apk", "--$currentMode")
        if (-not $ok) {
            Log-Message "APK build command failed for $currentMode mode. Check log file for compiler or gradle errors." "ERROR"
            exit 1
        }

        $expectedApk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$currentMode.apk"
        if (-not (Test-Path $expectedApk)) {
            Log-Message "Expected APK was not found at: $expectedApk" "ERROR"
            exit 1
        }

        $builtArtifacts += (Get-Item $expectedApk)
    }

    # ---------------------------------------------------------
    # 6. Verify Artifacts & Report
    # ---------------------------------------------------------
    Log-Message "============================================================" "SUCCESS"
    Log-Message "BUILD SUCCEEDED!" "SUCCESS"
    Log-Message "Generated APK Artifact(s):" "SUCCESS"

    foreach ($apkItem in $builtArtifacts) {
        $apkSizeMb = [math]::Round($apkItem.Length / 1MB, 2)
        $apkModified = $apkItem.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Log-Message "  - Path:     $($apkItem.FullName)" "SUCCESS"
        Log-Message "    Size:     $apkSizeMb MB ($($apkItem.Length) bytes)" "SUCCESS"
        Log-Message "    Modified: $apkModified" "SUCCESS"
    }

    Log-Message "Log saved at: $logFile" "INFO"
    Log-Message "============================================================" "SUCCESS"

    exit 0
}
finally {
    & $cleanUp
}