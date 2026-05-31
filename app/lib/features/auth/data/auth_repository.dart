import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/http/api_client.dart';

/// Talks to the backend pre-auth `/auth` endpoints.
///
/// The magic-link SEND is proxied through our backend so the client never has
/// to resolve the Supabase domain (which fails on some networks). The callback
/// is unaffected — supabase_flutter still completes the session from the deep
/// link on-device.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Asks the backend to send a Supabase magic-link email to [email].
  Future<void> sendMagicLink(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/magic-link',
      data: {'email': email, 'redirectTo': Env.authRedirectUrl},
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
