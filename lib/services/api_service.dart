import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/models/transaction.dart'; // Import the Transaction model

class ApiService {
  static const String baseUrl = "http://localhost:8001/api"; // Adjust to your backend URL
  // static const String baseUrl = "http://10.0.2.2:8001/api"; // Adjust to your backend URL
  String? _accessToken;
  String? _refreshToken;

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // Get the access token
  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get the refresh token
  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> register(String username, String password, {String? email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );

    if (response.statusCode == 201) {
      // Registration successful, now log the user in
      await login(username, password);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveTokens(data['access'], data['refresh']);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/'), // Adjust the endpoint as needed
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user data: ${response.body}');
    }
  }

  // Save tokens to SharedPreferences
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveTokens(data['access'], refreshToken);
      return true;
    }
    return false;
  }

  // Generic method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
      Future<http.Response> Function(String token) request) async {
    String? token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    var response = await request(token);
    if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      final refreshed = await refreshAccessToken();
      if (!refreshed) throw Exception('Session expired. Please log in again.');

      token = await getAccessToken();
      response = await request(token!);
    }
    return response;
  }

  // Fetch all transactions
  Future<List<Transaction>> getTransactions() async {
    final response = await makeAuthenticatedRequest((token) =>
        http.get(
          Uri.parse('$baseUrl/transactions/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Transaction.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch transactions: ${response.body}');
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    final response = await makeAuthenticatedRequest((token) async {
      return await http.post(
        Uri.parse('$baseUrl/transactions/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(transaction.toJson()),
      );
    });

    if (response.statusCode != 201) {
      throw Exception('Failed to add transaction: ${response.body}');
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(int id, Transaction transaction) async {
    final response = await makeAuthenticatedRequest((token) async {
      return await http.put(
        Uri.parse('$baseUrl/transactions/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(transaction.toJson()),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction: ${response.body}');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    final response = await makeAuthenticatedRequest((token) =>
        http.delete(
          Uri.parse('$baseUrl/transactions/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete transaction: ${response.body}');
    }
  }

  // Fetch financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final response = await makeAuthenticatedRequest((token) =>
        http.get(
          Uri.parse('$baseUrl/finances/summary/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch financial summary: ${response.body}');
  }

  Future<Map<String, dynamic>> getReports({
    String? type,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (categories != null && categories.isNotEmpty) {
      queryParams['category'] =
          categories.join(','); // Changed 'categories' to 'category'
    }
    if (startDate != null) {
      queryParams['date_from'] = startDate.toIso8601String().split(
          'T')[0]; // Changed 'start_date' to 'date_from' and fixed format
    }
    if (endDate != null) {
      queryParams['date_to'] = endDate.toIso8601String().split(
          'T')[0]; // Changed 'end_date' to 'date_to' and fixed format
    }

    final uri = Uri.parse('$baseUrl/reports/').replace(
        queryParameters: queryParams);

    final response = await makeAuthenticatedRequest((token) async {
      return await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reports: ${response.body}');
    }

    return json.decode(response.body);
  }

  Future<List<String>> getCategories() async {
    final response = await makeAuthenticatedRequest((token) =>
        http.get(
          Uri.parse('$baseUrl/categories/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Failed to fetch categories: ${response.body}');
  }
}
