import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themePreferenceKey = 'theme_preference';

  ThemeProvider() {
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToSystemThemeChanges();
    });
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString(_themePreferenceKey);
    _themeMode = _themeModeFromString(storedTheme) ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themeModeToString(mode));
  }

  void _listenToSystemThemeChanges() {
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        notifyListeners(); // Only notify if we're using system theme
      }
    };
  }

  // Helper methods
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode? _themeModeFromString(String? modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}