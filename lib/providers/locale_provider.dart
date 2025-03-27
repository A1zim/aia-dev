// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  // Список поддерживаемых языков
  static const List<String> supportedLocales = ['en', 'ky', 'ru'];
  
  // Ключ для сохранения локали в SharedPreferences
  static const String _localeKey = 'selected_locale';
  
  // Текущая локаль, по умолчанию английский
  Locale _locale = const Locale('en');

  LocaleProvider() {
    // Загружаем сохранённую локаль при инициализации
    _loadLocale();
  }

  // Геттер для получения текущей локали
  Locale get locale => _locale;

  // Метод для установки новой локали
  void setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    
    // Сохраняем выбранную локаль
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  // Метод для загрузки сохранённой локали
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null && supportedLocales.contains(savedLocale)) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }
}