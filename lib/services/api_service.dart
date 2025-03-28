import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/models/transaction.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Adjust to your backend URL
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

    if (response.statusCode != 201) {
      throw Exception('Failed to register: ${response.body}');
    }
    // Do not log in here; wait for email verification
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

  Future<void> verifyEmail(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-email/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to verify email: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
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

  Future<void> updateUserProfile({String? nickname}) async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await makeAuthenticatedRequest((token) async {
      return await http.patch(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (nickname != null) 'nickname': nickname,
        }),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await makeAuthenticatedRequest((token) async {
      return await http.post(
        Uri.parse('$baseUrl/users/me/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

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

  Future<http.Response> makeAuthenticatedRequest(
      Future<http.Response> Function(String token) request) async {
    String? token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    var response = await request(token);
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) throw Exception('Session expired. Please log in again.');

      token = await getAccessToken();
      response = await request(token!);
    }
    return response;
  }

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
      queryParams['category'] = categories.join(',');
    }
    if (startDate != null) {
      queryParams['date_from'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['date_to'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('$baseUrl/reports/').replace(queryParameters: queryParams);

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

  Future<List<String>> getUserCurrencies() async {
    final response = await makeAuthenticatedRequest((token) =>
        http.get(
          Uri.parse('$baseUrl/currencies/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Failed to fetch user currencies: ${response.body}');
  }

  Future<void> addUserCurrency(String currency) async {
    final response = await makeAuthenticatedRequest((token) async {
      return await http.post(
        Uri.parse('$baseUrl/currencies/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'currency': currency}),
      );
    });

    if (response.statusCode != 201) {
      throw Exception('Failed to add currency: ${response.body}');
    }
  }

  Future<void> deleteUserCurrency(String currency) async {
    final response = await makeAuthenticatedRequest((token) =>
        http.delete(
          Uri.parse('$baseUrl/currencies/$currency/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete currency: ${response.body}');
    }
  }
}
