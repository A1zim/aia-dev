class Transaction {
  final int id;
  final int user;
  final String type;
  final String category;
  final double amount; // Amount in KGS (Soms)
  final String description;
  final String timestamp;
  final String username;
  final String? originalCurrency; // The currency in which the amount was entered
  final double? originalAmount; // The original amount before conversion to KGS

  Transaction({
    required this.id,
    required this.user,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.username,
    this.originalCurrency,
    this.originalAmount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      user: json['user'],
      type: json['type'],
      category: json['category'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      timestamp: json['timestamp'],
      username: json['username'],
      originalCurrency: json['originalCurrency'],
      originalAmount: json['originalAmount'] != null ? double.parse(json['originalAmount'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'type': type,
      'category': category,
      'amount': double.parse(amount.toStringAsFixed(2)), // Ensure 2 decimal places
      'description': description,
      'timestamp': timestamp,
      'username': username,
      'originalCurrency': originalCurrency,
      'originalAmount': originalAmount != null ? double.parse(originalAmount!.toStringAsFixed(2)) : null,
    };
  }
}