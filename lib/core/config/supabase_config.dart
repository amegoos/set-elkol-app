import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration reader for Supabase runtime settings.
/// Supports compile-time `--dart-define` as well as `.env` assets.
abstract final class SupabaseConfig {
  SupabaseConfig._();

  static const String fallbackUrl = 'https://pyaiuwzabcgdopclnmxk.supabase.co';

  /// Resolves the Supabase project URL from:
  /// 1. Compile-time `--dart-define=SUPABASE_URL=...`
  /// 2. `.env` file `SUPABASE_URL=...`
  /// 3. Default fallback URL: `https://pyaiuwzabcgdopclnmxk.supabase.co`
  static String _env(String key) {
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key]?.trim() ?? '';
  }

  /// Resolves the Supabase project URL from:
  /// 1. Compile-time `--dart-define=SUPABASE_URL=...`
  /// 2. `.env` file `SUPABASE_URL=...`
  /// 3. Default fallback URL: `https://pyaiuwzabcgdopclnmxk.supabase.co`
  static String get url {
    const defineUrl = String.fromEnvironment('SUPABASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl.trim();

    final envUrl = _env('SUPABASE_URL');
    if (envUrl.isNotEmpty && !envUrl.contains('your-project')) {
      return envUrl;
    }
    return fallbackUrl;
  }

  /// Resolves the Supabase Anon / Publishable Key from:
  /// 1. Compile-time `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`
  /// 2. Compile-time `--dart-define=SUPABASE_ANON_KEY=...`
  /// 3. `.env` file `SUPABASE_PUBLISHABLE_KEY=...`
  /// 4. `.env` file `SUPABASE_ANON_KEY=...`
  static String get key {
    const definePub = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (definePub.isNotEmpty) return definePub.trim();

    const defineAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defineAnon.isNotEmpty) return defineAnon.trim();

    final envPub = _env('SUPABASE_PUBLISHABLE_KEY');
    if (envPub.isNotEmpty) return envPub;

    final envAnon = _env('SUPABASE_ANON_KEY');
    if (envAnon.isNotEmpty) return envAnon;

    return '';
  }

  /// Checks if the key is a genuine key rather than empty or placeholder string.
  static bool get hasValidKey {
    final k = key;
    return k.isNotEmpty &&
        !k.contains('your-anon-key') &&
        !k.contains('your-publishable-key') &&
        !k.contains('placeholder');
  }

  /// Safe placeholder JWT to prevent crash during offline startup before real key is set.
  static const String placeholderKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2MDAwMDAwMDAsImV4cCI6MTkwMDAwMDAwMH0.placeholder';

  /// Active key passed to `Supabase.initialize`.
  static String get activeAnonKey => hasValidKey ? key : placeholderKey;
}
