/// Compile-time configuration, supplied via `--dart-define` (never hardcoded,
/// never committed). See README "Running the app" for the run commands.
///
/// Example:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx \
///     --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000
abstract final class Env {
  /// Supabase project URL, e.g. https://xxxx.supabase.co
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (anon) key — safe to ship in the client.
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Our backend base URL. Defaults to the Android emulator loopback to the
  /// host machine (`10.0.2.2` reaches the host's `localhost`).
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Custom URL scheme + host the magic-link redirect uses to reopen the app.
  /// Must be whitelisted in Supabase → Auth → URL Configuration as a redirect
  /// URL, and is registered as an Android intent filter (see AndroidManifest).
  static const authRedirectScheme = 'form';
  static const authRedirectUrl = 'form://login-callback';

  /// True once the Supabase credentials have been provided at build time.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
