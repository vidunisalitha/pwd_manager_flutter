import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/core/crypto/hasher.dart';
import 'package:pwd_manager_flutter/core/utils/biometric_service.dart';
import 'package:pwd_manager_flutter/data/database/db_helper.dart';
import 'package:pwd_manager_flutter/data/local/secure_store.dart';

class AuthRepository {
  final BiometricService _biometricService = BiometricService();

  Future<bool> isFirstTimer() async {
    final storedUser = await SecureStore.instance.getUserName();
    return storedUser == null;
  }

  Future<String?> getStoredUsername() async {
    return await SecureStore.instance.getUserName();
  }

  Future<bool> signUp(String username, String pin) async {
    try {
      final result = await Hasher.hashPinForStorage(pin);

      await SecureStore.instance.saveUserData(
        userName: username,
        masterHash: result['hash'].toString(),
        salt: result['salt'].toString(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<SecretKey?> login(String pin) async {
    final storedHash = await SecureStore.instance.getMasterHash();
    final storedSalt = await SecureStore.instance.getSalt();

    if (storedHash == null || storedSalt == null) return null;

    final isValid = await Hasher.verifyPin(
      enteredPin: pin,
      storedHashBase64: storedHash,
      storedSaltBase64: storedSalt,
    );

    if (isValid) {
      final masterKey = await Hasher.deriveKey(
        pin,
        base64Decode(storedSalt),
      );

      await DBHelper.instance.getDatabase(storedHash);
      return masterKey;
    }

    return null;
  }

  Future<SecretKey?> loginWithBiometrics() async {
    bool isEnabled = await SecureStore.instance.isBiometricEnabled();
    if (!isEnabled) return null;

    bool authenticated = await _biometricService.authenticate();
    if (authenticated) {
      String? cachedPin = await SecureStore.instance.getCachedPin();

      if (cachedPin != null) {
        return await login(cachedPin);
      }
    }
    return null;
  }

  Future<void> logout() async {
    await DBHelper.instance.closeDatabase();
  }
}
