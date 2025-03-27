import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/services/notification_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/widgets/drawer.dart';

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

  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
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
      final userCurrencies = await _apiService.getUserCurrencies();
      final rates = <String, double>{};

      final combinedCurrencies = userCurrencies;

      for (var currency in combinedCurrencies) {
        if (currency == 'KGS') {
          rates[currency] = 1.0;
        } else {
          final rate = _currencyApiService.getConversionRate('KGS', currency);
          rates[currency] = rate;
        }
      }

      setState(() {
        _currencies = combinedCurrencies;
        _exchangeRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load currencies: $e';
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: 'Failed to load currencies: $e',
        isError: true,
      );
    }
  }

  void _loadAllCurrencies() {
    _allCurrencies = _currencyApiService.getAllCurrencies();
    _currencyToCountry = _currencyApiService.getCurrencyToCountryMap();
    _filteredCurrencies = [];
    _searchController.addListener(_filterCurrencies);
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
      return (currency.toUpperCase().contains(query) || country.toUpperCase().contains(query)) && !_currencies.contains(currency);
    }).toList();

    final rates = <String, double>{};
    for (var currency in filtered) {
      if (currency == 'KGS') {
        rates[currency] = 1.0;
      } else {
        try {
          final rate = _currencyApiService.getConversionRate('KGS', currency);
          rates[currency] = rate;
        } catch (e) {
          continue;
        }
      }
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
        message: 'Currency changed to $currency',
      );

      // Close the drawer if it's open
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.pop(context); // Close the drawer
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
            (route) => false,
      );
    }
  }

  void _addCurrency(String currency) async {
    try {
      await _apiService.addUserCurrency(currency);

      final rate = currency == 'KGS' ? 1.0 : _currencyApiService.getConversionRate('KGS', currency);

      setState(() {
        _currencies.add(currency);
        _exchangeRates[currency] = rate;
        _filterCurrencies();
      });

      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      await currencyProvider.refreshCurrencies();

      NotificationService.showNotification(
        context,
        message: '$currency added successfully',
      );

      await _fetchCurrencies();
    } catch (e) {
      String errorMessage = 'Failed to add currency: $e';
      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = '$currency already exists for this user';
      } else if (e.toString().contains('KGS is included by default')) {
        errorMessage = 'KGS is included by default and cannot be added';
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
        message: 'Cannot delete KGS',
        isError: true,
      );
      return;
    }

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Currency',
          style: AppTextStyles.subheading(context),
        ),
        content: Text(
          'Are you sure you want to delete $currency?',
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body(context),
            ),
          ),
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
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
        await _apiService.deleteUserCurrency(currency);

        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        if (currencyProvider.currency == currency) {
          await currencyProvider.setCurrency('KGS', 1.0);
        }

        setState(() {
          _currencies.remove(currency);
          _exchangeRates.remove(currency);
          _filterCurrencies();
        });

        await currencyProvider.refreshCurrencies();

        NotificationService.showNotification(
          context,
          message: '$currency deleted successfully',
        );

        await _fetchCurrencies();
      } catch (e) {
        NotificationService.showNotification(
          context,
          message: 'Failed to delete currency: $e',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Currencies',
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
      drawer: CustomDrawer(
        currentRoute: '/currency',
        parentContext: context,
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
                  'Retry',
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
                        backgroundColor: isSelected
                            ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        child: Text(
                          currency,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '$currency - $country',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '1 $currency = ${rate.toStringAsFixed(2)} KGS',
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                      labelText: 'Search by Currency or Country (e.g., JPY or Japan)',
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
                              title: Text(
                                '$currency - $country',
                                style: AppTextStyles.body(context),
                              ),
                              subtitle: Text(
                                '1 $currency = ${rate.toStringAsFixed(2)} KGS',
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
    );
  }
}