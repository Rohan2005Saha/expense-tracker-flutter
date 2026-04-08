import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _loadThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleThemeMode() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _saveThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedThemeMode = prefs.getString(_themeModeKey);

    if (savedThemeMode == ThemeMode.dark.name) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeMode.name);
  }
}
