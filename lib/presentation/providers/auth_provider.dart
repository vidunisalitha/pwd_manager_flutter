import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/core/crypto/hasher.dart';
import 'package:pwd_manager_flutter/core/utils/biometric_service.dart';
import 'package:pwd_manager_flutter/data/database/db_helper.dart';
import 'package:pwd_manager_flutter/data/local/secure_store.dart';

enum AuthStatus {
  unknown,
  firstTimer,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  SecretKey? _masterKey;
  String? _userName;

  AuthStatus get status => _status;
  SecretKey? get masterKey => _masterKey;
  String? get userName => _userName;

  final BiometricService _biometricService = BiometricService();

  Future<void> checkAuthStatus() async {
    final storedUser = await SecureStore.instance.getUserName();

    if(storedUser == null) {
      _status = AuthStatus.firstTimer;
    }
    else {
      _userName = storedUser;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> signUp(String username, String pin) async {
    try {
      final result = await Hasher.hashPinForStorage(pin);

      await SecureStore.instance.saveUserData(
        userName: username,
        masterHash: result['hash'].toString(),
        salt: result['salt'].toString(),
      );

      _userName = username;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String pin) async {
    final storedHash = await SecureStore.instance.getMasterHash();
    final storedSalt = await SecureStore.instance.getSalt();

    if(storedHash == null || storedSalt == null) return false;

    final isValid = await Hasher.verifyPin(
      enteredPin: pin,
      storedHashBase64: storedHash,
      storedSaltBase64: storedSalt,
    );

    if(isValid) {
      _masterKey = await Hasher.deriveKey(pin, storedSalt.split(',').map(int.parse).toList());

      await DBHelper.instance.getDatabase(storedHash);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithBiometrics() async {
    bool isEnabled = await SecureStore.instance.isBiometricEnabled();
    if(!isEnabled) return false;

    bool authenticated = await _biometricService.authenticate();
    if(authenticated){
      String? cachedPin = await SecureStore.instance.getCachedPin();

      if(cachedPin != null){
        return await login(cachedPin);
      }
    }
    return false;
  }

  Future<void> logout() async {
    _masterKey = null;
    await DBHelper.instance.closeDatabase();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}