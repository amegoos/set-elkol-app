<#
.SYNOPSIS
    Debounced file watcher that triggers build_apk.ps1 when coding changes finish.
.DESCRIPTION
    Monitors lib/, assets/, pubspec.yaml for changes.
    Ignores build/, .dart_tool/, .git/, and temporary editor files.
    Debounces triggers by waiting for a quiet window ($DebounceSeconds, default 5s)
    before running scripts\build_apk.ps1.
    Prevents simultaneous/overlapping builds.
.PARAMETER DebounceSeconds
    Seconds to wait after the last change before triggering the build (default: 5).
#>

[CmdletBinding()]
param(
    [int]$DebounceSeconds = 5
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$buildScript = Join-Path $PSScriptRoot "build_apk.ps1"
if (-not (Test-Path $buildScript)) {
    throw "Build script not found: $buildScript"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Set El Kol - Debounced Auto-Build Watcher" -ForegroundColor Cyan
Write-Host "Monitoring: $projectRoot" -ForegroundColor Cyan
Write-Host "Debounce window: $DebounceSeconds seconds" -ForegroundColor Cyan
Write-Host "Ignored: build/, .dart_tool/, .git/, .idea/, .vscode/" -ForegroundColor DarkGray
Write-Host "Press Ctrl+C to stop watching at any time." -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan

# Create file system watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $projectRoot
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size'

$global:pendingChanges = $false
$global:lastChangeTime = [DateTime]::MinValue
$global:isBuilding = $false

# Filter logic
$action = {
    param($source, $eventArgs)
    $path = $eventArgs.FullPath
    
    # Ignore build artifacts, git, editor temp files, dotfiles
    if ($path -match "[\\/](build|\.dart_tool|\.git|\.idea|\.vscode)[\\/]" -or
        $path -match "\.(tmp|bak|lock|swp)$" -or
        $path -match "[\\/]build\.log$" -or
        $path -match "[\\/]\.build\.lock$") {
        return
    }

    # Only react to Dart code, assets, or pubspec.yaml changes
    if ($path -match "\.dart$" -or $path -match "pubspec\.(yaml|lock)$" -or $path -match "[\\/]assets[\\/]") {
        $global:pendingChanges = $true
        $global:lastChangeTime = [DateTime]::UtcNow
        $name = Split-Path -Leaf $path
        Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] File changed: $name" -ForegroundColor Yellow
    }
}

Register-ObjectEvent $watcher 'Changed' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Created' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Deleted' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Renamed' -Action $action | Out-Null

try {
    while ($true) {
        Start-Sleep -Milliseconds 500

        if ($global:pendingChanges -and -not $global:isBuilding) {
            $elapsed = ([DateTime]::UtcNow - $global:lastChangeTime).TotalSeconds
            if ($elapsed -ge $DebounceSeconds) {
                $global:pendingChanges = $false
                $global:isBuilding = $true

                Write-Host ""
                Write-Host ">> Quiet window elapsed ($DebounceSeconds s). Triggering build_apk.ps1..." -ForegroundColor Green
                try {
                    & powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript
                }
                catch {
                    Write-Host "Error executing build script: $_" -ForegroundColor Red
                }
                finally {
                    $global:isBuilding = $false
                    Write-Host ">> Watcher standing by for next change..." -ForegroundColor Cyan
                    Write-Host ""
                }
            }
        }
    }
}
finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | Unregister-Event -Force -ErrorAction SilentlyContinue
    Write-Host "Watcher stopped." -ForegroundColor Yellow
}