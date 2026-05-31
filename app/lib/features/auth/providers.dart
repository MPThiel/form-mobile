import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/supabase_service.dart';
import '../../core/storage/local_cache.dart';
import 'data/auth_repository.dart';

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
      // Proxied through our backend (see AuthRepository) rather than calling
      // Supabase directly, so the send works on networks that can't resolve
      // the Supabase domain.
      await ref.read(authRepositoryProvider).sendMagicLink(trimmed);
      state = AuthLinkSent(trimmed);
    } on DioException catch (e) {
      state = AuthFailure(_messageFor(e));
    } catch (_) {
      state = const AuthFailure(
        'Could not send the magic link. Check your connection and try again.',
      );
    }
  }

  String _messageFor(DioException e) {
    if (e.response?.statusCode == 429) {
      return 'Too many requests. Please wait a few minutes and try again.';
    }
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Could not send the magic link. Check your connection and try again.';
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
