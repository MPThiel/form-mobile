import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the `supabase_flutter` client so the rest of the app
/// never imports the SDK directly. Exposes only what FORM needs for Phase 1
/// (the current session, sign-out, and the auth-change stream that completes
/// when the magic-link deep link is processed).
///
/// Note: sending the magic link is NOT done here — it is proxied through our
/// backend (see AuthRepository) so it works on networks that can't resolve the
/// Supabase domain. Only the callback/session handling stays client-side.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  GoTrueClient get auth => _client.auth;
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  String? get email => _client.auth.currentUser?.email;
  String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Emits on every auth change (sign-in via magic link, token refresh,
  /// sign-out). Drives router redirects.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signOut() => _client.auth.signOut();
}

/// The live Supabase client. Requires `Supabase.initialize` to have run in
/// `main()` — overridden in tests.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

/// Auth change stream, surfaced as a provider for widgets/router that want to
/// react to sign-in / sign-out.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).onAuthStateChange;
});

/// The signed-in user's email. A thin provider so widgets depend on this rather
/// than the SDK-backed service directly (keeps them trivially testable).
final currentEmailProvider = Provider<String?>((ref) {
  return ref.watch(supabaseServiceProvider).email;
});
