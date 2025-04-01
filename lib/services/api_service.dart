import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aia_wallet/models/transaction.dart';

class PaginatedResponse<T> {
  final List<T> items;
  final bool hasMore;
  final int? totalCount;

  PaginatedResponse({
    required this.items,
    required this.hasMore,
    this.totalCount,
  });
}

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000//api";
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

  // Save tokens to SharedPreferences
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Clear tokens from memory and SharedPreferences
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

  // Generic method to make authenticated requests with token refresh
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

  Future<void> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveTokens(data['access'], data['refresh']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('${errorData['error'] ?? 'Login failed'}: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> register(String username, String password, {String? email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data; // Return the response data which includes user info
      } else {
        final errorData = json.decode(response.body);
        throw Exception('${errorData['error'] ?? 'Registration failed'}: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('${errorData['error'] ?? 'Verification failed'}: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Email verification failed: ${e.toString()}');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('${errorData['error'] ?? 'Password reset failed'}: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData() async {
    final response = await makeAuthenticatedRequest((token) => http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user data: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Update user profile (e.g., nickname)
  Future<void> updateUserProfile({String? nickname}) async {
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
      throw Exception('Failed to update profile: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Change user password
  Future<void> changePassword(String oldPassword, String newPassword) async {
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
      throw Exception('Failed to change password: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  Future<void> clearData(String password) async {
    final response = await makeAuthenticatedRequest((token) => http.delete(
      Uri.parse('$baseUrl/transactions/clear/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'password': password}),
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to clear data: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Get list of transactions
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': pageSize.toString(),
    };
    if (type != null && type != 'all') {
      queryParams['type'] = type;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/transactions/').replace(queryParameters: queryParams);

    final response = await makeAuthenticatedRequest((token) => http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      final List<Transaction> transactions = results.map((json) => Transaction.fromJson(json)).toList();

      bool hasMore;
      if (data.containsKey('next') && data['next'] != null) {
        hasMore = true;
      } else if (data.containsKey('count')) {
        final int totalCount = data['count'];
        hasMore = (page * pageSize) < totalCount;
      } else {
        hasMore = transactions.length == pageSize;
      }

      return PaginatedResponse<Transaction>(
        items: transactions,
        hasMore: hasMore,
        totalCount: data.containsKey('count') ? data['count'] : null,
      );
    }
    throw Exception('Failed to fetch transactions: ${json.decode(response.body)['error'] ?? response.body}');
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
      throw Exception('Failed to add transaction: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(int id, Transaction transaction) async {
    final response = await makeAuthenticatedRequest((token) async {
      // Log the request body to verify the timestamp
      final requestBody = json.encode(transaction.toJson());
      print('Updating transaction $id with body: $requestBody');

      return await http.put(
        Uri.parse('$baseUrl/transactions/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    final response = await makeAuthenticatedRequest((token) => http.delete(
      Uri.parse('$baseUrl/transactions/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete transaction: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final response = await makeAuthenticatedRequest((token) => http.get(
      Uri.parse('$baseUrl/finances/summary/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch financial summary: ${json.decode(response.body)['error'] ?? response.body}');
  }

  // Get financial reports with optional filters
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
      throw Exception('Failed to fetch reports: ${json.decode(response.body)['error'] ?? response.body}');
    }

    return json.decode(response.body);
  }

  // Get list of categories
  Future<List<String>> getCategories() async {
    final response = await makeAuthenticatedRequest((token) => http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Failed to fetch categories: ${json.decode(response.body)['error'] ?? response.body}');
  }

  // Get user's currencies
  Future<List<String>> getUserCurrencies() async {
    final response = await makeAuthenticatedRequest((token) => http.get(
      Uri.parse('$baseUrl/currencies/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Failed to fetch user currencies: ${json.decode(response.body)['error'] ?? response.body}');
  }

  // Add a currency to the user's list
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
      throw Exception('Failed to add currency: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }

  // Delete a currency from the user's list
  Future<void> deleteUserCurrency(String currency) async {
    final response = await makeAuthenticatedRequest((token) => http.delete(
      Uri.parse('$baseUrl/currencies/$currency/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete currency: ${json.decode(response.body)['error'] ?? response.body}');
    }
  }
}