import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/core/crypto/hasher.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> verifyCurrentPin(String pin) async {
    final storedHash = await SecureStore.instance.getMasterHash();
    final storedSalt = await SecureStore.instance.getSalt();

    if (storedHash == null || storedSalt == null) return false;

    return Hasher.verifyPin(
      enteredPin: pin,
      storedHashBase64: storedHash,
      storedSaltBase64: storedSalt,
    );
  }

  Future<bool> updateCredentials({
    required String username,
    required String currentPin,
    required String newPin,
    required String masterHash,
    required String salt,
  }) async {
    final isValid = await verifyCurrentPin(currentPin);
    if (!isValid) return false;

    final oldHash = await SecureStore.instance.getMasterHash();
    final biometricsWereEnabled = await SecureStore.instance.isBiometricEnabled();

    if (oldHash == null) return false;

    // DB rotation is handled by the caller (VaultRepository.rotateVaultEncryptionKey)
    // to avoid issues with PRAGMA rekey on some platforms. Persist new credentials
    // after the DB has been rotated.
    await SecureStore.instance.updateUserCredentials(
      userName: username,
      masterHash: masterHash,
      salt: salt,
    );

    if (biometricsWereEnabled) {
      await SecureStore.instance.cachePin(newPin);
      await SecureStore.instance.setBiometricEnabled(true);
    } else {
      await SecureStore.instance.deleteCachedPin();
      await SecureStore.instance.setBiometricEnabled(false);
    }

    return true;
  }

  Future<bool> setBiometricEnabled({
    required String pin,
    required bool enabled,
  }) async {
    final isValid = await verifyCurrentPin(pin);
    if (!isValid) return false;

    await SecureStore.instance.setBiometricEnabled(enabled);
    if (enabled) {
      await SecureStore.instance.cachePin(pin);
    } else {
      await SecureStore.instance.deleteCachedPin();
    }
    return true;
  }

  Future<bool> isBiometricEnabled() async {
    return SecureStore.instance.isBiometricEnabled();
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
      final masterKey = await Hasher.deriveKey(pin, base64Decode(storedSalt));

      try {
        await DBHelper.instance.getDatabase(storedHash);
        return masterKey;
      } catch (e, st) {
        debugPrint('Failed to open DB after successful PIN verification: $e\n$st');
        return null;
      }
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
