import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/supabase_service.dart';
import '../config/env.dart';

/// Dio client pointed at our backend, with an interceptor that attaches the
/// current Supabase JWT as `Authorization: Bearer <jwt>` on every request.
/// The token is read live from the session each call, so refreshes are picked
/// up automatically.
Dio createApiClient(SupabaseService supabase) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.backendBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = supabase.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}

final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(ref.watch(supabaseServiceProvider));
});
