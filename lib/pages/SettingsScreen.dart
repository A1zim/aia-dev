import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/main.dart';
import 'package:aia_wallet/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  String _selectedCurrency = 'KGS'; // Default to KGS
  double _exchangeRate = 1.0; // Default rate (KGS to KGS)
  String _selectedLanguage = 'ky'; // Default to Kyrgyz
  bool _isLoading = false;

  List<String> _availableCurrencies = [];

  @override
  void initState() {
    super.initState();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _selectedLanguage = localeProvider.locale.languageCode;
    _loadAvailableCurrencies();
  }

  Future<void> _loadAvailableCurrencies() async {
    try {
      final userCurrencies = await _apiService.getUserCurrencies();
      setState(() {
        _availableCurrencies = userCurrencies;
      });
    } catch (e) {
      print('Failed to load available currencies: $e');
      NotificationService.showNotification(
        context,
        message: 'Failed to load available currencies: $e',
        isError: true,
      );
      setState(() {
        _availableCurrencies = ['KGS']; // Fallback to KGS if there's an error
      });
    }
  }

  void _selectCurrency(String? value) {
    if (value == null || value == _selectedCurrency) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rate = _currencyApiService.getConversionRate('KGS', value);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      currencyProvider.setCurrency(value, rate);

      setState(() {
        _selectedCurrency = value;
        _exchangeRate = rate;
      });

      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.currencyChanged(value),
        isError: false,
      );
    } catch (e) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.currencyChangeFailed(e.toString()),
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectLanguage(String? value) {
    if (value == null || value == _selectedLanguage) return;

    setState(() {
      _selectedLanguage = value;
    });

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    localeProvider.setLocale(Locale(value));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logout, style: AppTextStyles.subheading(context)),
          content: Text(AppLocalizations.of(context)!.logoutConfirm, style: AppTextStyles.body(context)),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel, style: AppTextStyles.body(context)),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                await _apiService.clearTokens();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text(
                AppLocalizations.of(context)!.confirmLogout,
                style: AppTextStyles.body(context).copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCurrencyColor(String currency) {
    final Map<String, Color> currencyColors = {
      'KGS': const Color(0xFFEF5350), // Red for KGS
      'USD': const Color(0xFF4CAF50), // Green for USD
      'EUR': const Color(0xFF42A5F5), // Blue for EUR
      'JPY': const Color(0xFFFFCA28), // Yellow for JPY
      'GBP': const Color(0xFFAB47BC), // Purple for GBP
      'AED': const Color(0xFF26C6DA), // Cyan for AED
    };
    return currencyColors[currency] ?? Colors.grey.withOpacity(0.8);
  }

  Color _getLanguageColor(String language) {
    final Map<String, Color> languageColors = {
      'en': const Color(0xFFEF5350), // Red for English
      'ky': const Color(0xFF4CAF50), // Green for Kyrgyz
      'ru': const Color(0xFF42A5F5), // Blue for Russian
    };
    return languageColors[language] ?? Colors.grey.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    _selectedCurrency = currencyProvider.currency; // Sync with provider
    _exchangeRate = currencyProvider.exchangeRate;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle, style: AppTextStyles.heading(context)),
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
        iconTheme: IconThemeData(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: SwitchListTile.adaptive(
                  title: Text(AppLocalizations.of(context)!.darkMode,
                      style: AppTextStyles.body(context).copyWith(fontSize: 16)),
                  subtitle: Text(
                    isDark
                        ? AppLocalizations.of(context)!.darkModeEnabled
                        : AppLocalizations.of(context)!.darkModeDisabled,
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(AppLocalizations.of(context)!.selectCurrency,
                    style: AppTextStyles.body(context).copyWith(fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _availableCurrencies.contains(_selectedCurrency) ? _selectedCurrency : 'KGS',
                      onChanged: _isLoading ? null : _selectCurrency,
                      decoration: AppInputStyles.dropdown(context, labelText: 'Currency'),
                      items: _availableCurrencies.map((currency) {
                        final country = _currencyApiService.getCountryForCurrency(currency);
                        final currencyColor = _getCurrencyColor(currency);
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: currencyColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$currency - $country'),
                            ],
                          ),
                        );
                      }).toList(),
                      itemHeight: 50,
                      style: AppTextStyles.body(context).copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      icon: AppInputStyles.dropdownIcon(context),
                      menuMaxHeight: 300.0,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 56.0, top: 8.0),
                      child: Text(
                        '1 KGS = ${_exchangeRate.toStringAsFixed(3)} $_selectedCurrency',
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                )
                    : null,
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(AppLocalizations.of(context)!.selectLanguage,
                    style: AppTextStyles.body(context).copyWith(fontSize: 16)),
                subtitle: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  onChanged: _selectLanguage,
                  decoration: AppInputStyles.dropdown(context).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(AppLocalizations.of(context)!.languageEnglish)),
                    DropdownMenuItem(value: 'ky', child: Text(AppLocalizations.of(context)!.languageKyrgyz)),
                    DropdownMenuItem(value: 'ru', child: Text(AppLocalizations.of(context)!.languageRussian)),
                  ].map((item) {
                    final languageColor = _getLanguageColor(item.value!);
                    return DropdownMenuItem<String>(
                      value: item.value,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: languageColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.child.toString().replaceAll('Text("', '').replaceAll('")', '')),
                        ],
                      ),
                    );
                  }).toList(),
                  itemHeight: 50,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(AppLocalizations.of(context)!.logout,
                    style: AppTextStyles.body(context).copyWith(fontSize: 16)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}