import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';

/// Talks to the backend `/me` endpoints. Phase 1 only needs the first-sign-in
/// provisioning call; Profile fields are filled by the Phase 2 onboarding
/// wizard.
class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  /// Idempotently create-or-fetch the User row on the backend. Returns the
  /// account payload (`{ user, profile }`). `profile` is null until onboarding.
  Future<Map<String, dynamic>> provision() async {
    final res = await _dio.post<Map<String, dynamic>>('/me');
    return res.data ?? const <String, dynamic>{};
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(apiClientProvider));
});

/// Fires `POST /me` once when the signed-in Home screen mounts. Kept separate
/// from rendering so the screen can show the email immediately (from the
/// session) and surface backend sync as its own loading/error state.
final provisionAccountProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      return ref.watch(accountRepositoryProvider).provision();
    });
