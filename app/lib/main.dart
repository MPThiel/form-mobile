import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/auth/secure_supabase_storage.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Supabase when credentials were supplied at build time.
  // Without them the app shows a configuration screen (see FormApp).
  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        // PKCE is required for the magic-link deep-link flow.
        authFlowType: AuthFlowType.pkce,
        // Persist the session + PKCE verifier in the Keychain / Keystore only.
        localStorage: const SecureLocalStorage(),
        pkceAsyncStorage: SecureGotrueAsyncStorage(),
      ),
    );
  }

  runApp(const ProviderScope(child: FormApp()));
}
