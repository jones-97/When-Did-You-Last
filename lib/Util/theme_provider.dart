import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeFromSystem(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    _themeMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  

  // ThemeProvider() {
  //   _loadTheme();
  // }

  // Future<void> _loadTheme() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _isDarkMode = prefs.getBool('darkMode') ?? false;
  //   notifyListeners();
  // }

  // Future<void> toggleTheme(bool isDark) async {
  //   _isDarkMode = isDark;
  //   final prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('darkMode', isDark);
  //   notifyListeners();
  // }
}
