import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class Hasher {
  static final _algorithm = Argon2id(
    parallelism: 1,
    memory: 16384,
    iterations: 2,
    hashLength: 32,
  );

  static Future<SecretKeyData> deriveKey(String pin, List<int> salt) async {
    final secretKey = await _algorithm.deriveKeyFromPassword(
      password: pin,
      nonce: salt
    );

    return secretKey.extract();
  }

  static Future<Map<String, String>> hashPinForStorage(String pin) async {
    final salt = SecretKeyData.random(length: 16).bytes;

    final keyData = await deriveKey(pin, salt);

    return {
      'salt' : base64Encode(salt),
      'hash' : base64Encode(keyData.bytes),
    };
  }

  static Future<bool> verifyPin(
    {
      required String enteredPin,
      required String storedHashBase64,
      required String storedSaltBase64,
    }
  ) async {
    final salt = base64Decode(storedSaltBase64);
    final keyData = await deriveKey(enteredPin, salt);
    final computedHash = base64Encode(keyData.bytes);

    return computedHash == storedHashBase64;
  }
}