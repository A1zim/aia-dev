import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider({ThemeMode initialMode = ThemeMode.system}) {
    _themeMode = initialMode;
  }

  // Load the saved theme mode from SharedPreferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode') ?? 'system';
    _themeMode = themeModeFromString(savedTheme);
    notifyListeners();
  }

  // Toggle between light and dark themes
  void toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeModeToString(_themeMode));
    notifyListeners();
  }

  // Convert string to ThemeMode
  ThemeMode themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // Convert ThemeMode to string
  String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  // Get the logo path based on the current theme
  String getLogoPath(BuildContext context) {
    // Determine the effective theme (resolves ThemeMode.system)
    final brightness = _themeMode == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness
        : (_themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    // Return the appropriate logo path
    return brightness == Brightness.dark
        ? 'assets/images/aia_logo_w.png'
        : 'assets/images/aia_logo_b.png';
  }
}