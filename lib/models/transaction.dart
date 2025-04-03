// models/transaction.dart
class Transaction {
  final int id;
  final int user;
  final String type;
  final String? defaultCategory; // Nullable to match backend
  final int? customCategory;     // Nullable, represents UserCategory ID
  final String? category;        // Computed field from backend, nullable
  final double amount;
  final String? description;     // Nullable to match backend
  final String timestamp;
  final String username;
  final String? originalCurrency; // Nullable
  final double? originalAmount;   // Nullable

  Transaction({
    required this.id,
    required this.user,
    required this.type,
    this.defaultCategory,
    this.customCategory,
    this.category,
    required this.amount,
    this.description,
    required this.timestamp,
    required this.username,
    this.originalCurrency,
    this.originalAmount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      user: json['user'] as int,
      type: json['type'] as String,
      defaultCategory: json['default_category'] as String?,
      customCategory: json['custom_category'] as int?, // ID of UserCategory or null
      category: json['category'] as String?,           // Computed category name
      amount: double.parse(json['amount'].toString()),
      description: json['description'] as String?,
      timestamp: json['timestamp'] as String,
      username: json['username'] as String,
      originalCurrency: json['original_currency'] as String?,
      originalAmount: json['original_amount'] != null
          ? double.parse(json['original_amount'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'type': type,
      'default_category': defaultCategory,
      'custom_category': customCategory,
      // Note: 'category' is computed on the backend, so it's not sent from frontend
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
      'username': username,
      'original_currency': originalCurrency,
      'original_amount': originalAmount,
    };
  }

  // Getter to mimic backend's get_category()
  String getCategory() {
    // Use the computed 'category' field from the backend if available
    if (category != null) {
      return category!;
    }
    // Fallback to defaultCategory if present, otherwise 'Uncategorized'
    return defaultCategory ?? 'Uncategorized';
  }
}