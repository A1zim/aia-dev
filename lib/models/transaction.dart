// models/transaction.dart
class Transaction {
  final int id;
  final int user;
  final String type;
  final String category;
  final double amount; // Store as double
  final String description;
  final String timestamp;
  final String username;

  Transaction({
    required this.id,
    required this.user,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.username,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      user: json['user'] as int,
      type: json['type'] as String,
      category: json['category'] as String,
      amount: double.parse(json['amount'].toString()), // Convert string to double
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
      'username': username,
    };
  }
}