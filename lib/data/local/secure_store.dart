import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._internal();
  static final SecureStore instance = SecureStore._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _keyUserSalt = 'user_salt_base64';
  static const _keyMasterHash = 'master_hash_base64';
  static const _keyUserName = 'user_name';
  static const _keyBiometricEnabled = 'biometric_enabled';

  Future<void> saveUserData(
    {
      required String userName,
      required String masterHash,
      required String salt,
    }
  ) async {
    await _storage.write(key: _keyUserSalt, value: salt);
    await _storage.write(key: _keyMasterHash, value: masterHash);
    await _storage.write(key: _keyUserName, value: userName);
  }

  Future<String?> getSalt() async => await _storage.read(key: _keyUserSalt);
  Future<String?> getMasterHash() async => await _storage.read(key: _keyMasterHash);
  Future<String?> getUserName() async => await _storage.read(key: _keyUserName);

  Future<void> updateUserInfo(String userName, String newMasterHash) async {
    await _storage.write(key: _keyUserName, value: userName);
    await _storage.write(key: _keyMasterHash, value: newMasterHash);
  }

  Future<void> setBiometicEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    String? value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}