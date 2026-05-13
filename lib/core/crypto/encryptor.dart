import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class Encryptor {
  static final _algorithm = AesGcm.with256bits();

  static Future<String> encrypt(String plainText, SecretKey masterKey) async {
    final bytes = utf8.encode(plainText);
    
    final secretBox = await _algorithm.encrypt(
      bytes,
      secretKey: masterKey,
    );

    return base64Encode(secretBox.concatenation());
  }

  static Future<String> decrypt(String encryptedBase64,  SecretKey masterKey) async {
    try {
      final combinedBytes = base64Decode(encryptedBase64);

      final secretBox = SecretBox.fromConcatenation(
        combinedBytes,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );

      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: masterKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      return 'Decryption failed: ${e.toString()}';
    }
  }
}