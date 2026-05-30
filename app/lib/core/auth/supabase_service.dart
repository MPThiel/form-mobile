import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around the `supabase_flutter` client so the rest of the app
/// never imports the SDK directly. Exposes only what FORM needs for Phase 1
/// (magic-link sign-in, the current session, sign-out).
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

  /// Sends a passwordless magic link. The email contains a link that reopens
  /// the app via [Env.authRedirectUrl]; `supabase_flutter` then completes the
  /// session from the deep link.
  Future<void> sendMagicLink(String email) {
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: Env.authRedirectUrl,
    );
  }

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
