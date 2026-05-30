import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/auth/supabase_service.dart';
import '../../core/storage/local_cache.dart';

/// UI state for the magic-link sign-in flow.
sealed class AuthFlowState {
  const AuthFlowState();
}

/// Showing the email input, ready for a new request.
class AuthIdle extends AuthFlowState {
  const AuthIdle();
}

/// Magic-link request in flight.
class AuthSendingLink extends AuthFlowState {
  const AuthSendingLink();
}

/// Link sent — show the "check your inbox" confirmation.
class AuthLinkSent extends AuthFlowState {
  const AuthLinkSent(this.email);
  final String email;
}

/// Request failed — show [message] and let the user retry.
class AuthFailure extends AuthFlowState {
  const AuthFailure(this.message);
  final String message;
}

/// Drives the sign-in screen and sign-out. The global signed-in/out status is
/// observed separately via [authStateChangesProvider] / the Supabase session,
/// which the router watches.
class AuthController extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthIdle();

  Future<void> sendMagicLink(String email) async {
    final trimmed = email.trim();
    state = const AuthSendingLink();
    try {
      await ref.read(supabaseServiceProvider).sendMagicLink(trimmed);
      state = AuthLinkSent(trimmed);
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
    } catch (_) {
      state = const AuthFailure(
        'Could not send the magic link. Check your connection and try again.',
      );
    }
  }

  /// Return to the email input from the confirmation / error state.
  void backToInput() => state = const AuthIdle();

  Future<void> signOut() async {
    await ref.read(supabaseServiceProvider).signOut();
    await ref.read(localCacheProvider).clear();
    state = const AuthIdle();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthFlowState>(
  AuthController.new,
);
