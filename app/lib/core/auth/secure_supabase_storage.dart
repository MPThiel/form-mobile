import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase persists the user session (which contains the JWT + refresh token)
/// and the PKCE code verifier. By default it uses SharedPreferences, which is
/// plaintext on disk. CLAUDE.md requires all tokens live only in
/// `flutter_secure_storage` (Keychain / Keystore), so we back both stores with
/// it here and wire them into `Supabase.initialize`.
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _sessionKey = 'form.supabase.session';

/// [LocalStorage] implementation backed by [FlutterSecureStorage]. Stores the
/// serialized Supabase session.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return _secureStorage.containsKey(key: _sessionKey);
  }

  @override
  Future<String?> accessToken() {
    return _secureStorage.read(key: _sessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    return _secureStorage.delete(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _secureStorage.write(key: _sessionKey, value: persistSessionString);
  }
}

/// [GotrueAsyncStorage] implementation backed by [FlutterSecureStorage]. Stores
/// the PKCE code verifier used by the magic-link flow.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) {
    return _secureStorage.read(key: key);
  }

  @override
  Future<void> removeItem({required String key}) {
    return _secureStorage.delete(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _secureStorage.write(key: key, value: value);
  }
}
