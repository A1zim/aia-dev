class UserFinances {
  final int? id;
  final double balance;
  final double income;
  final double expense;
  final String preferredCurrency;

  UserFinances({
    this.id,
    required this.balance,
    required this.income,
    required this.expense,
    required this.preferredCurrency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'balance': balance,
      'income': income,
      'expense': expense,
      'preferred_currency': preferredCurrency,
    };
  }

  factory UserFinances.fromMap(Map<String, dynamic> map) {
    return UserFinances(
      id: map['id'],
      balance: map['balance'].toDouble(),
      income: map['income'].toDouble(),
      expense: map['expense'].toDouble(),
      preferredCurrency: map['preferred_currency'],
    );
  }
}