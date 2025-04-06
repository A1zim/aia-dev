import 'package:flutter/material.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/providers/theme_provider.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  _CurrencyScreenState createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  List<String> _currencies = [];
  Map<String, double> _exchangeRates = {};
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  List<String> _allCurrencies = [];
  List<String> _filteredCurrencies = [];
  Map<String, double> _filteredExchangeRates = {};
  Map<String, String> _currencyToCountry = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
    _loadAllCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use CurrencyProvider to get the user's currencies
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final userCurrencies = currencyProvider.availableCurrencies;
      final rates = <String, double>{};

      for (var currency in userCurrencies) {
        if (currency == 'KGS') {
          rates[currency] = 1.0;
        } else {
          // Mock exchange rates (since no API)
          rates[currency] = _mockExchangeRate(currency);
        }
      }

      setState(() {
        _currencies = userCurrencies;
        _exchangeRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.currenciesLoadFailed(e.toString());
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.currenciesLoadFailed(e.toString()),
        isError: true,
      );
    }
  }

  void _loadAllCurrencies() {
    // Mock list of all currencies (since no CurrencyApiService)
    _allCurrencies = ['KGS', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'RUB'];
    // Mock currency-to-country mapping
    _currencyToCountry = {
      'KGS': 'Kyrgyzstan',
      'USD': 'United States',
      'EUR': 'Eurozone',
      'GBP': 'United Kingdom',
      'JPY': 'Japan',
      'CNY': 'China',
      'RUB': 'Russia',
    };
    _filteredCurrencies = [];
    _searchController.addListener(_filterCurrencies);
  }

  double _mockExchangeRate(String currency) {
    // Mock exchange rates for KGS to other currencies
    const mockRates = {
      'KGS': 1.0,
      'USD': 0.012, // 1 KGS = 0.012 USD
      'EUR': 0.011, // 1 KGS = 0.011 EUR
      'GBP': 0.009, // 1 KGS = 0.009 GBP
      'JPY': 1.75,  // 1 KGS = 1.75 JPY
      'CNY': 0.085, // 1 KGS = 0.085 CNY
      'RUB': 1.15,  // 1 KGS = 1.15 RUB
    };
    return mockRates[currency] ?? 1.0;
  }

  String _mockCurrencyFlag(String currency) {
    // Mock currency flags
    const flags = {
      'KGS': '🇰🇬',
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'JPY': '🇯🇵',
      'CNY': '🇨🇳',
      'RUB': '🇷🇺',
    };
    return flags[currency] ?? '🏳️';
  }

  void _filterCurrencies() {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCurrencies = [];
        _filteredExchangeRates = {};
      });
      return;
    }

    final filtered = _allCurrencies.where((currency) {
      final country = _currencyToCountry[currency] ?? '';
      return (currency.toUpperCase().contains(query) || country.toUpperCase().contains(query)) &&
          !_currencies.contains(currency);
    }).toList();

    final rates = <String, double>{};
    for (var currency in filtered) {
      rates[currency] = _mockExchangeRate(currency);
    }

    setState(() {
      _filteredCurrencies = filtered;
      _filteredExchangeRates = rates;
    });
  }

  void _selectCurrency(String currency) async {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final rate = _exchangeRates[currency] ?? 1.0;
    await currencyProvider.setCurrency(currency, rate);

    if (mounted) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.currencyChanged(currency),
      );

      // Navigate back to SettingsScreen instead of /main
      Navigator.pop(context);
    }
  }

  void _addCurrency(String currency) async {
    try {
      final rate = _mockExchangeRate(currency);

      setState(() {
        _currencies.add(currency);
        _exchangeRates[currency] = rate;
        _filterCurrencies();
      });

      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      await currencyProvider.addCurrency(currency);

      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.currencyAdded(currency),
      );

      await _fetchCurrencies();
    } catch (e) {
      String errorMessage = AppLocalizations.of(context)!.currenciesLoadFailed(e.toString());
      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = AppLocalizations.of(context)!.currencyExists(currency);
      } else if (e.toString().contains('KGS is included by default')) {
        errorMessage = AppLocalizations.of(context)!.kgsDefault;
      }

      NotificationService.showNotification(
        context,
        message: errorMessage,
        isError: true,
      );
    }
  }

  void _deleteCurrency(String currency) async {
    if (currency == 'KGS') {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.cannotDeleteKGS,
        isError: true,
      );
      return;
    }

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteCurrency,
          style: AppTextStyles.subheading(context),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirm(currency),
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTextStyles.body(context),
            ),
          ),
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTextStyles.body(context).copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        if (currencyProvider.currency == currency) {
          await currencyProvider.setCurrency('KGS', 1.0);
        }

        await currencyProvider.removeCurrency(currency);

        setState(() {
          _currencies.remove(currency);
          _exchangeRates.remove(currency);
          _filterCurrencies();
        });

        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.currencyDeleted(currency),
        );

        await _fetchCurrencies();
      } catch (e) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.currenciesLoadFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);

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
            // Custom Header with Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Navigate back to SettingsScreen
                      },
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.manageCurrencies,
                  style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              )
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.body(context).copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchCurrencies,
                      style: AppButtonStyles.elevatedButton(context),
                      child: Text(
                        AppLocalizations.of(context)!.retry,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _currencies.length,
                      itemBuilder: (context, index) {
                        final currency = _currencies[index];
                        final country = _currencyToCountry[currency] ?? 'Unknown';
                        final rate = _exchangeRates[currency] ?? 1.0;
                        final isSelected = currencyProvider.currency == currency;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              child: Text(
                                _mockCurrencyFlag(currency),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(
                              '$currency - $country',
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '1 $currency = ${(1 / rate).toStringAsFixed(2)} KGS',
                              style: AppTextStyles.body(context).copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  ),
                                if (currency != 'KGS')
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () => _deleteCurrency(currency),
                                  ),
                              ],
                            ),
                            onTap: () => _selectCurrency(currency),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: AppInputStyles.textField(context).copyWith(
                            labelText: AppLocalizations.of(context)!.searchCurrencyOrCountry,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                          ),
                          textCapitalization: TextCapitalization.none,
                        ),
                        const SizedBox(height: 8),
                        if (_filteredCurrencies.isNotEmpty)
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              itemCount: _filteredCurrencies.length,
                              itemBuilder: (context, index) {
                                final currency = _filteredCurrencies[index];
                                final country = _currencyToCountry[currency] ?? 'Unknown';
                                final rate = _filteredExchangeRates[currency] ?? 1.0;

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurface,
                                      child: Text(
                                        _mockCurrencyFlag(currency),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    title: Text(
                                      '$currency - $country',
                                      style: AppTextStyles.body(context),
                                    ),
                                    subtitle: Text(
                                      '1 $currency = ${(1 / rate).toStringAsFixed(2)} KGS',
                                      style: AppTextStyles.body(context).copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _addCurrency(currency),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}