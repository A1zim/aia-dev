import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:personal_finance/localization/app_localizations.dart';
import 'package:personal_finance/providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const SettingsScreen({super.key, this.onThemeToggle});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedCurrency = 'USD';
  late String _selectedLanguage;
  bool _isFingerprintEnabled = false;

  // Ключи для SharedPreferences
  static const String _currencyKey = 'selected_currency';
  static const String _fingerprintKey = 'fingerprint_enabled';

  @override
  void initState() {
    super.initState();
    // Инициализируем _selectedLanguage из текущей локали
    _selectedLanguage = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    // Загружаем сохранённые настройки
    _loadSettings();
  }

  // Загрузка сохранённых настроек
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString(_currencyKey) ?? 'USD';
      _isFingerprintEnabled = prefs.getBool(_fingerprintKey) ?? false;
    });
  }

  void _selectCurrency(String? value) async {
    setState(() {
      _selectedCurrency = value!;
    });
    // Сохраняем выбранную валюту
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, _selectedCurrency);
  }

  void _selectLanguage(String? value) {
    setState(() {
      _selectedLanguage = value!;
      // Обновляем локаль приложения через LocaleProvider
      Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(_selectedLanguage));
    });
  }

  void _toggleFingerprint(bool value) async {
    setState(() {
      _isFingerprintEnabled = value;
    });
    // Сохраняем состояние отпечатка пальца
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintKey, _isFingerprintEnabled);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context).logout,
            style: AppTextStyles.subheading(context),
          ),
          content: Text(
            AppLocalizations.of(context).confirmLogout,
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: AppTextStyles.body(context),
              ),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                await _apiService.clearTokens();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text(
                AppLocalizations.of(context).logout,
                style: AppTextStyles.body(context).copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: AppTextStyles.heading(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkPrimary, AppColors.darkSecondary]
                  : [AppColors.lightPrimary, AppColors.lightSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: SwitchListTile.adaptive(
                  title: Text(
                    localizations.darkMode,
                    style: AppTextStyles.body(context).copyWith(fontSize: 16),
                  ),
                  subtitle: Text(
                    isDark ? localizations.enabled : localizations.disabled,
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    widget.onThemeToggle?.call();
                  },
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Language Selection
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  localizations.selectLanguage,
                  style: AppTextStyles.body(context).copyWith(fontSize: 16),
                ),
                subtitle: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  onChanged: _selectLanguage,
                  decoration: AppInputStyles.dropdown(context).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(localizations.languageEnglish),
                    ),
                    DropdownMenuItem(
                      value: 'ky',
                      child: Text(localizations.languageKyrgyz),
                    ),
                    DropdownMenuItem(
                      value: 'ru',
                      child: Text(localizations.languageRussian),
                    ),
                  ],
                  itemHeight: 50,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Currency Selection
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  localizations.selectCurrency,
                  style: AppTextStyles.body(context).copyWith(fontSize: 16),
                ),
                subtitle: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  onChanged: _selectCurrency,
                  decoration: AppInputStyles.dropdown(context).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text(localizations.currencyUSD),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text(localizations.currencyEUR),
                    ),
                    DropdownMenuItem(
                      value: 'INR',
                      child: Text(localizations.currencyINR),
                    ),
                  ],
                  itemHeight: 50,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Fingerprint Authentication
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: SwitchListTile.adaptive(
                  title: Text(
                    localizations.enableFingerprint,
                    style: AppTextStyles.body(context).copyWith(fontSize: 16),
                  ),
                  subtitle: Text(
                    _isFingerprintEnabled ? localizations.enabled : localizations.disabled,
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: _isFingerprintEnabled,
                  onChanged: _toggleFingerprint,
                  secondary: Icon(
                    Icons.fingerprint,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Logout Option
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  localizations.logout,
                  style: AppTextStyles.body(context).copyWith(fontSize: 16),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}