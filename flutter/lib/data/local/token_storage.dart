import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value store for the signed-in account email.
/// Mirrors TokenStorage.kt (EncryptedSharedPreferences → flutter_secure_storage).
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _storage;

  static const _keyEmail = 'account_email';

  Future<void> saveAccountEmail(String email) =>
      _storage.write(key: _keyEmail, value: email);

  Future<String?> getAccountEmail() => _storage.read(key: _keyEmail);

  Future<bool> isSignedIn() async => (await getAccountEmail()) != null;

  Future<void> clear() => _storage.deleteAll();
}
