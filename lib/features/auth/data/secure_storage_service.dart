import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key used to store the JWT auth token in secure storage.
const kAuthTokenKey = 'auth_token';

/// Service wrapper around [FlutterSecureStorage] for auth token operations.
///
/// Provides a clean interface for reading, writing and deleting the JWT token.
/// This is NOT a Riverpod provider — it is a plain Dart service injected into
/// [AuthNotifier] via the [secureStorageServiceProvider] plain Provider.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  /// Reads the stored auth token.
  ///
  /// Returns `null` when no token is present (unauthenticated).
  Future<String?> readToken() async {
    return _storage.read(key: kAuthTokenKey);
  }

  /// Persists [token] to secure storage.
  Future<void> writeToken(String token) async {
    await _storage.write(key: kAuthTokenKey, value: token);
  }

  /// Deletes the stored auth token (logout).
  Future<void> deleteToken() async {
    await _storage.delete(key: kAuthTokenKey);
  }
}
