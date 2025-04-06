import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/providers/transaction_provider.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = 'KGS';
  double _exchangeRate = 1.0;
  List<String> _availableCurrencies = [];
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  TransactionProvider? _transactionProvider; // Add this to sync with TransactionProvider

  String get currency => _currency;
  double get exchangeRate => _exchangeRate;
  List<String> get availableCurrencies => _availableCurrencies;

  CurrencyProvider() {
    loadCurrency();
    _loadAvailableCurrencies();
  }

  // Method to set the TransactionProvider after initialization
  void setTransactionProvider(TransactionProvider transactionProvider) {
    _transactionProvider = transactionProvider;
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'KGS';
    _exchangeRate = prefs.getDouble('exchangeRate') ?? 1.0;
    // Sync with TransactionProvider if it's set
    if (_transactionProvider != null) {
      await _transactionProvider!.setPreferredCurrency(_currency);
    }
    notifyListeners();
  }

  Future<void> _loadAvailableCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencies = prefs.getStringList('availableCurrencies');
      final allCurrencies = _currencyApiService.getAllCurrencies();

      if (savedCurrencies != null && savedCurrencies.isNotEmpty) {
        _availableCurrencies = savedCurrencies.where((currency) => allCurrencies.contains(currency)).toList();
      } else {
        _availableCurrencies = ['KGS', 'USD', 'RUB', 'EUR', 'CNY'];
        await prefs.setStringList('availableCurrencies', _availableCurrencies);
      }

      if (!_availableCurrencies.contains(_currency)) {
        await setCurrency('KGS', 1.0);
      }
      notifyListeners();
    } catch (e) {
      print('Failed to load available currencies: $e');
      _availableCurrencies = ['KGS', 'USD', 'RUB', 'EUR', 'CNY'];
      notifyListeners();
    }
  }

  Future<void> setCurrency(String newCurrency, double newRate) async {
    _currency = newCurrency;
    _exchangeRate = newRate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currency);
    await prefs.setDouble('exchangeRate', _exchangeRate);
    // Sync with TransactionProvider
    if (_transactionProvider != null) {
      await _transactionProvider!.setPreferredCurrency(newCurrency);
    }
    notifyListeners();
  }

  Future<void> addCurrency(String currency) async {
    if (!_availableCurrencies.contains(currency)) {
      _availableCurrencies.add(currency);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('availableCurrencies', _availableCurrencies);
      notifyListeners();
    }
  }

  Future<void> removeCurrency(String currency) async {
    if (_availableCurrencies.contains(currency)) {
      _availableCurrencies.remove(currency);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('availableCurrencies', _availableCurrencies);

      if (_currency == currency) {
        await setCurrency('KGS', 1.0);
      }
      notifyListeners();
    }
  }

  double convertAmount(double amountInKGS) {
    return amountInKGS * _exchangeRate;
  }

  Future<void> refreshCurrencies() async {
    await _loadAvailableCurrencies();
  }
}