import 'package:flutter/foundation.dart';
import '../providers/transaction_provider.dart';

class Transaction {
  static const String fallbackExpenseCategory = 'other_expense';
  static const String fallbackIncomeCategory = 'other_income';

  final int? id; // Made nullable
  final String type;
  final String? defaultCategory;
  final int? customCategoryId;
  final double amount;
  final String? description;
  final String timestamp;
  final String? originalCurrency;
  final double? originalAmount;

  Transaction({
    this.id,
    required String type,
    this.defaultCategory,
    this.customCategoryId,
    required this.amount,
    this.description,
    required this.timestamp,
    this.originalCurrency,
    this.originalAmount,
  }) : type = type {
    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Type must be either "income" or "expense", got: $type');
    }
  }

  factory Transaction.create({
    required String type,
    String? defaultCategory,
    int? customCategoryId,
    required double amount,
    String? description,
    required DateTime timestamp,
    String? originalCurrency,
    double? originalAmount,
  }) {
    return Transaction(
      id: null,
      type: type,
      defaultCategory: defaultCategory,
      customCategoryId: customCategoryId,
      amount: amount,
      description: description,
      timestamp: timestamp.toIso8601String(),
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'type': type,
      'default_category': defaultCategory,
      'custom_category_id': customCategoryId,
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
      'original_currency': originalCurrency,
      'original_amount': originalAmount,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      defaultCategory: map['default_category'] as String?,
      customCategoryId: map['custom_category_id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      timestamp: map['timestamp'] as String,
      originalCurrency: map['original_currency'] as String?,
      originalAmount: (map['original_amount'] as num?)?.toDouble(),
    );
  }

  String getCategory(TransactionProvider provider) {
    if (defaultCategory != null) {
      return defaultCategory!;
    }
    if (customCategoryId != null) {
      final category = provider.getCategoryById(customCategoryId!);
      return category?.name ?? 'Unknown';
    }
    return type == 'income' ? fallbackIncomeCategory : fallbackExpenseCategory;
  }

  DateTime get timestampAsDateTime {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      debugPrint('Error parsing timestamp "$timestamp": $e');
      throw FormatException('Invalid timestamp format: $timestamp');
    }
  }

  Transaction copyWith({
    int? id,
    String? type,
    String? defaultCategory,
    int? customCategoryId,
    double? amount,
    String? description,
    String? timestamp,
    String? originalCurrency,
    double? originalAmount,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, defaultCategory: $defaultCategory, customCategoryId: $customCategoryId, amount: $amount, description: $description, timestamp: $timestamp, originalCurrency: $originalCurrency, originalAmount: $originalAmount)';
  }
}