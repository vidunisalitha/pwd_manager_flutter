import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pwd_manager_flutter/data/models/account_model.dart';
import 'package:pwd_manager_flutter/data/repositories/vault_repository.dart';

class VaultProvider extends ChangeNotifier {
  final VaultRepository _vaultRepository = VaultRepository();

  List<AccountModel> _accounts = [];
  List<AccountModel> _filteredAccounts = [];
  bool _isLoading = false;
  String? _error;

  List<AccountModel> get accounts => _accounts;
  List<AccountModel> get filteredAccounts => _filteredAccounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAccounts(SecretKey masterKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _vaultRepository.getAllAccounts(masterKey);
      _filteredAccounts = _accounts;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _accounts = [];
      _filteredAccounts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAccount({
    required String serviceName,
    required String username,
    required String password,
    required SecretKey masterKey,
  }) async {
    try {
      await _vaultRepository.insertAccount(
        serviceName: serviceName,
        username: username,
        plainTextPassword: password,
        masterKey: masterKey,
      );

      await loadAccounts(masterKey);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAccount({
    required int id,
    required String serviceName,
    required String username,
    required String password,
    required SecretKey masterKey,
  }) async {
    try {
      await _vaultRepository.updateAccount(
        id: id,
        serviceName: serviceName,
        username: username,
        plainTextPassword: password,
        masterKey: masterKey,
      );

      // Reload accounts to reflect changes
      await loadAccounts(masterKey);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int id, SecretKey masterKey) async {
    try {
      await _vaultRepository.deleteAccount(id);

      // Reload accounts after deletion
      await loadAccounts(masterKey);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> searchAccounts(String query, SecretKey masterKey) async {
    try {
      if (query.isEmpty) {
        _filteredAccounts = _accounts;
      } else {
        _filteredAccounts = await _vaultRepository.searchAccounts(query, masterKey);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _filteredAccounts = [];
    }

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
