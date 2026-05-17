import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBoimetricAvailable() async {
    try {
      final bool canAuthenticatewithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticatewithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan to access your passwords',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate;
    } catch (e) {
      // LocalAuth on some emulator/device setups throws LocalAuthException
      // (e.g. requires FragmentActivity on Android). Catch all errors here and
      // return false so the app can continue without crashing.
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }
}
