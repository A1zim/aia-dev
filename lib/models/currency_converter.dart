import 'package:personal_finance/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyConverter {
  static final ApiService _apiService = ApiService();
  static const String _defaultCurrency = 'KGS'; // Kyrgyz Som
  
  // Get the user's preferred currency
  static Future<String> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? _defaultCurrency;
  }
  
  // Convert an amount to the user's preferred currency
  static Future<double> convertToPreferredCurrency(
      double amount, String fromCurrency) async {
    final String toCurrency = await getPreferredCurrency();
    if (fromCurrency == toCurrency) {
      return amount;
    }
    
    try {
      final rate = await _apiService.getExchangeRate(fromCurrency, toCurrency);
      return amount * rate;
    } catch (e) {
      print('Error converting currency: $e');
      return amount; // Return original amount if conversion fails
    }
  }
  
  // Format amount with currency symbol
  static String formatWithCurrency(double amount, String currency) {
    String symbol;
    bool symbolAfter = false; // Add this flag
    
    switch (currency) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'JPY':
        symbol = '¥';
        break;
      case 'INR':
        symbol = '₹';
        break;
      case 'KGS':
        symbol = 'сом';
        symbolAfter = true; // Set flag for KGS
        break;
      default:
        symbol = currency;
    }
    
    // Format depending on whether symbol should be before or after
    return symbolAfter 
        ? '${amount.toStringAsFixed(2)} $symbol'
        : '$symbol${amount.toStringAsFixed(2)}';
  }
  
  // Format amount with preferred currency symbol - modified to actually convert the amount
  static Future<String> formatWithPreferredCurrency(double amount, [String fromCurrency = 'KGS']) async {
    final String toCurrency = await getPreferredCurrency();
    double convertedAmount = await convertToPreferredCurrency(amount, fromCurrency);
    return formatWithCurrency(convertedAmount, toCurrency);
  }
  
  // Get conversion rate between two currencies
  static Future<double> getConversionRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return 1.0;
    }
    
    try {
      return await _apiService.getExchangeRate(fromCurrency, toCurrency);
    } catch (e) {
      print('Error getting conversion rate: $e');
      return 1.0; // Default to 1:1 if there's an error
    }
  }
}
