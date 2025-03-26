import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/services/api_service.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = 'KGS';
  double _exchangeRate = 1.0;
  List<String> _availableCurrencies = ['KGS', 'USD', 'RUB', 'EUR', 'CNY'];

  String get currency => _currency;
  double get exchangeRate => _exchangeRate;
  List<String> get availableCurrencies => _availableCurrencies;

  final ApiService _apiService = ApiService();

  CurrencyProvider() {
    loadCurrency();
    _loadAvailableCurrencies();
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'KGS';
    _exchangeRate = prefs.getDouble('exchangeRate') ?? 1.0;
    notifyListeners();
  }

  Future<void> _loadAvailableCurrencies() async {
    try {
      final userCurrencies = await _apiService.getUserCurrencies();
      // Combine default currencies with user-added currencies
      final defaultCurrencies = ['KGS', 'USD', 'RUB', 'EUR', 'CNY'];
      _availableCurrencies = {...defaultCurrencies, ...userCurrencies}.toList();

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
    notifyListeners();
  }

  double convertAmount(double amountInKGS) {
    return amountInKGS * _exchangeRate;
  }

  Future<void> refreshCurrencies() async {
    await _loadAvailableCurrencies();
  }
}