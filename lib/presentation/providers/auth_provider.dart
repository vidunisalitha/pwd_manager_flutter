import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/data/repositories/auth_repository.dart';

enum AuthStatus { unknown, firstTimer, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  SecretKey? _masterKey;
  String? _userName;

  final AuthRepository _authRepository = AuthRepository();

  AuthStatus get status => _status;
  SecretKey? get masterKey => _masterKey;
  String? get userName => _userName;

  Future<void> checkAuthStatus() async {
    final isFirstTimer = await _authRepository.isFirstTimer();

    if (isFirstTimer) {
      _status = AuthStatus.firstTimer;
    } else {
      _userName = await _authRepository.getStoredUsername();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> signUp(String username, String pin) async {
    try {
      final success = await _authRepository.signUp(username, pin);

      if (success) {
        _userName = username;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String pin) async {
    final masterKey = await _authRepository.login(pin);

    if (masterKey != null) {
      _masterKey = masterKey;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithBiometrics() async {
    final masterKey = await _authRepository.loginWithBiometrics();

    if (masterKey != null) {
      _masterKey = masterKey;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _masterKey = null;
    await _authRepository.logout();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateCredentials({
    required String username,
    required String currentPin,
    required String newPin,
    required String masterHash,
    required String salt,
    required SecretKey newMasterKey,
  }) async {
    final success = await _authRepository.updateCredentials(
      username: username,
      currentPin: currentPin,
      newPin: newPin,
      masterHash: masterHash,
      salt: salt,
    );

    if (success) {
      _userName = username;
      _masterKey = newMasterKey;
      notifyListeners();
    }

    return success;
  }

  Future<bool> setBiometricEnabled({
    required String pin,
    required bool enabled,
  }) async {
    return _authRepository.setBiometricEnabled(pin: pin, enabled: enabled);
  }

  Future<bool> verifyCurrentPin(String pin) async {
    return _authRepository.verifyCurrentPin(pin);
  }

  Future<bool> isBiometricEnabled() async {
    return _authRepository.isBiometricEnabled();
  }
}
