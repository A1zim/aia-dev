import 'package:flutter/material.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/main.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:aia_wallet/utils/scaling.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  String _selectedCurrency = 'KGS';
  double _exchangeRate = 1.0;
  String _selectedLanguage = 'ky';
  bool _isLoading = false;

  List<String> _availableCurrencies = [];
  static const String appVersion = '0.0.3';

  @override
  void initState() {
    super.initState();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _selectedLanguage = localeProvider.locale.languageCode;
    _loadAvailableCurrencies();
  }

  Future<void> _loadAvailableCurrencies() async {
    try {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      setState(() {
        _availableCurrencies = currencyProvider.availableCurrencies;
      });
    } catch (e) {
      print('Failed to load available currencies: $e');
      NotificationService.showNotification(
        context,
        message: 'Failed to load available currencies: $e',
        isError: true,
      );
      setState(() {
        _availableCurrencies = ['KGS'];
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

  Future<void> _exitApp() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.lightSurface, AppColors.lightBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
              border: Border.all(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.exitApp,
                    style: AppTextStyles.subheading(context),
                  ),
                  SizedBox(height: Scaling.scalePadding(8)),
                  Text(
                    AppLocalizations.of(context)!.exitAppConfirm,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Scaling.scalePadding(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      SystemNavigator.pop();
    }
  }

  void _showCurrencyPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: Scaling.scalePadding(12),
                    horizontal: Scaling.scalePadding(16),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Scaling.scale(12)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: Scaling.scaleIcon(24),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
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
                    itemCount: _availableCurrencies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: Icon(
                            Icons.add,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            size: Scaling.scaleIcon(24),
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.addCurrency,
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/currency');
                          },
                        );
                      }

                      final currencyIndex = index - 1;
                      final currency = _availableCurrencies[currencyIndex];
                      final isSelected = currency == _selectedCurrency;
                      return ListTile(
                        leading: Text(
                          _currencyApiService.getCurrencyFlag(currency),
                          style: TextStyle(fontSize: Scaling.scaleFont(20)),
                        ),
                        title: Text(
                          '$currency - ${_currencyApiService.getCountryForCurrency(currency)}',
                          style: AppTextStyles.body(context).copyWith(
                            color: isSelected
                                ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                                : null,
                          ),
                        ),
                        trailing: Text(
                          _currencyApiService.getCurrencySymbol(currency),
                          style: TextStyle(fontSize: Scaling.scaleFont(14)),
                        ),
                        tileColor: isSelected
                            ? (isDark
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: Scaling.scalePadding(12),
                    horizontal: Scaling.scalePadding(16),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Scaling.scale(12)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkAccent
                            : AppColors.lightAccent,
                        size: Scaling.scaleIcon(24),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
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
                        leading: Text(
                          language['flag']!,
                          style: TextStyle(fontSize: Scaling.scaleFont(20)),
                        ),
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
    Scaling.init(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    _selectedCurrency = currencyProvider.currency;
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Scaling.scalePadding(16.0),
                vertical: Scaling.scalePadding(10.0),
              ),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          height: Scaling.scale(40),
                          width: Scaling.scale(40),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
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
                    SizedBox(width: Scaling.scalePadding(24)),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: Scaling.scalePadding(8.0)),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.settingsTitle,
                  style: AppTextStyles.heading(context).copyWith(fontSize: Scaling.scaleFont(18)),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Scaling.scale(12)),
                      ),
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      child: SwitchListTile.adaptive(
                        title: Text(
                          AppLocalizations.of(context)!.darkMode,
                          style: AppTextStyles.body(context).copyWith(fontSize: Scaling.scaleFont(16)),
                        ),
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
                          size: Scaling.scaleIcon(24),
                        ),
                        activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    ),
                    SizedBox(height: Scaling.scalePadding(16)),
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
                                size: Scaling.scaleIcon(24),
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
                                  borderRadius: BorderRadius.circular(Scaling.scale(12)),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Scaling.scalePadding(16),
                                  vertical: Scaling.scalePadding(12),
                                ),
                              ),
                            ),
                            SizedBox(width: Scaling.scalePadding(8)),
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
                                    fontSize: Scaling.scaleFont(12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isLoading)
                          SizedBox(
                            width: Scaling.scale(20),
                            height: Scaling.scale(20),
                            child: CircularProgressIndicator(
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: Scaling.scalePadding(16)),
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
                                size: Scaling.scaleIcon(24),
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
                                  borderRadius: BorderRadius.circular(Scaling.scale(12)),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Scaling.scalePadding(16),
                                  vertical: Scaling.scalePadding(12),
                                ),
                              ),
                            ),
                            SizedBox(width: Scaling.scalePadding(16)),
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
                    SizedBox(height: Scaling.scalePadding(16)),
                    Divider(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                      thickness: 1,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.category,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: Scaling.scaleIcon(24),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.categories,
                        style: AppTextStyles.body(context).copyWith(fontSize: Scaling.scaleFont(16)),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/categories');
                      },
                    ),
                    Divider(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                      thickness: 1,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.exit_to_app,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: Scaling.scaleIcon(24),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.exitApp,
                        style: AppTextStyles.body(context).copyWith(fontSize: Scaling.scaleFont(16)),
                      ),
                      onTap: _exitApp,
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        'Version: $appVersion',
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: Scaling.scaleFont(12),
                        ),
                      ),
                    ),
                    SizedBox(height: Scaling.scalePadding(16)),
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