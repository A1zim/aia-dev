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

  Future<void> _selectCurrency(String value) async {
    if (value == _selectedCurrency) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rate = _currencyApiService.getConversionRate('KGS', value);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      await currencyProvider.setCurrency(value, rate);

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

  void _selectLanguage(String value) {
    if (value == _selectedLanguage) return;

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

  void _showCurrencyPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkAccent
                            : AppColors.lightAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.selectCurrency,
                        style: AppTextStyles.subheading(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _availableCurrencies[index];
                      final isSelected = currency == _selectedCurrency;
                      return ListTile(
                        leading: Text(_currencyApiService.getCurrencyFlag(currency)),
                        title: Text(
                          '$currency - ${_currencyApiService.getCountryForCurrency(currency)}',
                          style: AppTextStyles.body(context).copyWith(
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkAccent
                                : AppColors.lightAccent)
                                : null,
                          ),
                        ),
                        trailing: Text(_currencyApiService.getCurrencySymbol(currency)),
                        tileColor: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkAccent.withOpacity(0.1)
                            : AppColors.lightAccent.withOpacity(0.1))
                            : null,
                        onTap: () {
                          _selectCurrency(currency);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    final languages = [
      {'code': 'en', 'name': AppLocalizations.of(context)!.languageEnglish, 'flag': '🇺🇸'},
      {'code': 'ky', 'name': AppLocalizations.of(context)!.languageKyrgyz, 'flag': '🇰🇬'},
      {'code': 'ru', 'name': AppLocalizations.of(context)!.languageRussian, 'flag': '🇷🇺'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkAccent
                            : AppColors.lightAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.selectLanguage,
                        style: AppTextStyles.subheading(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = language['code'] == _selectedLanguage;
                      return ListTile(
                        leading: Text(language['flag']!),
                        title: Text(
                          language['name']!,
                          style: AppTextStyles.body(context).copyWith(
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkAccent
                                : AppColors.lightAccent)
                                : null,
                          ),
                        ),
                        tileColor: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkAccent.withOpacity(0.1)
                            : AppColors.lightAccent.withOpacity(0.1))
                            : null,
                        onTap: () {
                          _selectLanguage(language['code']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    _selectedCurrency = currencyProvider.currency; // Sync with provider
    _exchangeRate = currencyProvider.exchangeRate;

    return Scaffold(
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
        child: Column(
          children: [
            // Custom Header like ReportsScreen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.normal,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.settingsTitle,
                  style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Expanded(
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
                    Divider(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                      thickness: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _showCurrencyPicker,
                              icon: Icon(
                                Icons.attach_money,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.selectCurrency,
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_currencyApiService.getCurrencyFlag(_selectedCurrency)} $_selectedCurrency '
                                      '(${_currencyApiService.getCurrencySymbol(_selectedCurrency)})',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  '1 KGS = ${_exchangeRate.toStringAsFixed(3)} $_selectedCurrency',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                      thickness: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showLanguagePicker,
                              icon: Icon(
                                Icons.language,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.selectLanguage,
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${_selectedLanguage == 'en' ? '🇺🇸' : _selectedLanguage == 'ky' ? '🇰🇬' : '🇷🇺'} '
                                  '${_selectedLanguage == 'en' ? AppLocalizations.of(context)!.languageEnglish : _selectedLanguage == 'ky' ? AppLocalizations.of(context)!.languageKyrgyz : AppLocalizations.of(context)!.languageRussian}',
                              style: AppTextStyles.body(context).copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                      thickness: 1,
                    ),
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
          ],
        ),
      ),
    );
  }
}