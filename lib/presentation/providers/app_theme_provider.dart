import 'package:flutter/material.dart';
import 'package:pwd_manager_flutter/data/local/secure_store.dart';

class AppThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemeMode() async {
    if (_loaded) return;

    final storedMode = await SecureStore.instance.getThemeMode();
    switch (storedMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await SecureStore.instance.setThemeMode(_themeMode.name);
    notifyListeners();
  }
}