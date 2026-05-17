import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/core/crypto/encryptor.dart';
import 'package:pwd_manager_flutter/data/database/db_helper.dart';
import 'package:pwd_manager_flutter/data/models/account_model.dart';

class VaultRepository {
  final DBHelper _dbHelper = DBHelper.instance;

  Future<List<AccountModel>> getAllAccounts(SecretKey masterKey) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getAllAccounts();

    List<AccountModel> accounts = [];
    for (var map in maps) {
      AccountModel account = AccountModel.fromMap(map);
      String decryptedPassword = await Encryptor.decrypt(
        account.encryptedPassword,
        masterKey,
      );
      accounts.add(account.copyWith(decryptedPassword: decryptedPassword));
    }

    return accounts;
  }

  Future<void> insertAccount({
    required String serviceName,
    required String username,
    required String plainTextPassword,
    required SecretKey masterKey,
  }) async {
    String encryptedPassword = await Encryptor.encrypt(
      plainTextPassword,
      masterKey,
    );

    Map<String, dynamic> row = {
      'service_name': serviceName,
      'username': username,
      'encrypted_password': encryptedPassword,
    };

    await _dbHelper.insertAccount(row);
  }

  Future<void> updateAccount({
    required int id,
    required String serviceName,
    required String username,
    required String plainTextPassword,
    required SecretKey masterKey,
  }) async {
    String encryptedPassword = await Encryptor.encrypt(
      plainTextPassword,
      masterKey,
    );

    Map<String, dynamic> row = {
      'id': id,
      'service_name': serviceName,
      'username': username,
      'encrypted_password': encryptedPassword,
    };

    await _dbHelper.updateAccount(row);
  }

  Future<void> deleteAccount(int id) async {
    await _dbHelper.deleteAccount(id);
  }

  Future<void> rotateVaultEncryptionKey({
    required SecretKey oldMasterKey,
    required SecretKey newMasterKey,
  }) async {
    // Read all accounts decrypted with the old key
    final accounts = await getAllAccounts(oldMasterKey);

    // Prepare rows encrypted with the new key for a safe DB recreate
    final List<Map<String, dynamic>> newRows = [];

    for (final account in accounts) {
      final decryptedPassword = account.decryptedPassword;

      if (decryptedPassword == null ||
          decryptedPassword.startsWith('Decryption failed')) {
        throw Exception('Failed to decrypt an account during key rotation');
      }

      final encryptedPassword = await Encryptor.encrypt(
        decryptedPassword,
        newMasterKey,
      );

      newRows.add({
        'service_name': account.serviceName,
        'username': account.username,
        'encrypted_password': encryptedPassword,
      });
    }

    // Use DBHelper to recreate the database with the new encrypted rows.
    final newKeyBytes = await newMasterKey.extractBytes();
    final newPasswordString = base64Encode(newKeyBytes);

    await _dbHelper.recreateDatabaseWithRows(newPasswordString, newRows);
  }

  Future<List<AccountModel>> searchAccounts(
    String query,
    SecretKey masterKey,
  ) async {
    final allAccounts = await getAllAccounts(masterKey);
    return allAccounts
        .where(
          (account) =>
              account.serviceName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
