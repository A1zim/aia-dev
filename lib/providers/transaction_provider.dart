import 'package:flutter/material.dart';
import 'dart:math'; // For Random
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/user_finances.dart';
import '../models/category.dart';
import 'package:aia_wallet/database/database_helper.dart';
import '../generated/app_localizations.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  List<String> _dateKeys = [];
  UserFinances? _userFinances;
  List<Category> _categories = [];
  Map<String, Color> _customCategoryColors = {}; // Map to store colors for custom categories
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Filter variables
  bool _filterIncome = false;
  bool _filterExpense = true; // Default: expense active
  String _dateFilter = 'Monthly'; // Default filter
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime _calendarDate = DateTime.now();
  DateTime? _tempStartDate;

  // Getters
  List<Transaction> get transactions => _transactions;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  Map<String, List<Transaction>> get groupedTransactions => _groupedTransactions;
  List<String> get dateKeys => _dateKeys;
  UserFinances? get userFinances => _userFinances;
  List<Category> get categories => _categories;
  Map<String, Color> get customCategoryColors => _customCategoryColors;
  bool get filterIncome => _filterIncome;
  bool get filterExpense => _filterExpense;
  String get dateFilter => _dateFilter;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  DateTime get calendarDate => _calendarDate;
  DateTime? get tempStartDate => _tempStartDate;

  TransactionProvider() {
    // Initialize with default date range (current month)
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, now.month, 1);
    _selectedEndDate = DateTime(now.year, now.month + 1, 0); // Last day of the month
  }

  // Initialize the provider (called from main.dart)
  Future<void> init() async {
    await _initializeUserFinances();
    await loadData();
  }

  // Load all data from the database
  Future<void> loadData() async {
    try {
      final db = await _dbHelper.database;
      // Load transactions
      final transactionMaps = await db.query('transactions', orderBy: 'timestamp DESC');
      _transactions = transactionMaps.map((map) => Transaction.fromMap(map)).toList();

      // Load user finances
      final financeMaps = await db.query('user_finances', limit: 1);
      if (financeMaps.isNotEmpty) {
        _userFinances = UserFinances.fromMap(financeMaps.first);
      } else {
        // If no user_finances record exists, create a default one
        await _initializeUserFinances();
      }

      // Load categories
      final categoryMaps = await db.query('categories');
      _categories = categoryMaps.map((map) => Category.fromMap(map)).toList();

      // Assign colors to existing custom categories
      for (var category in _categories) {
        if (!_customCategoryColors.containsKey(category.name.toLowerCase())) {
          _customCategoryColors[category.name.toLowerCase()] = _generateRandomColor();
        }
      }

      // Apply filters and group transactions
      _applyDateFilter();
      groupTransactionsByDate();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
      rethrow;
    }
  }

  // Initialize user_finances if it doesn't exist
  Future<void> _initializeUserFinances() async {
    final db = await _dbHelper.database;
    final financeMaps = await db.query('user_finances', limit: 1);
    if (financeMaps.isEmpty) {
      _userFinances = UserFinances(
        id: 1,
        balance: 0.0,
        income: 0.0,
        expense: 0.0,
        preferredCurrency: 'KGS',
      );
      await db.insert('user_finances', _userFinances!.toMap());
    }
  }

  Category? getCategoryById(int id) {
    return _categories.firstWhere(
          (category) => category.id == id,
      orElse: () => Category(id: 0, name: 'Unknown', type: ''),
    );
  }

  Future<void> setPreferredCurrency(String currency) async {
    if (_userFinances == null) {
      await _initializeUserFinances();
    }
    final db = await _dbHelper.database;
    _userFinances = UserFinances(
      id: _userFinances!.id,
      balance: _userFinances!.balance,
      income: _userFinances!.income,
      expense: _userFinances!.expense,
      preferredCurrency: currency,
    );
    await db.update(
      'user_finances',
      _userFinances!.toMap(),
      where: 'id = ?',
      whereArgs: [_userFinances!.id],
    );
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    try {
      await db.transaction((sqflite.Transaction txn) async {
        final id = await txn.insert('transactions', transaction.toMap());
        debugPrint('Inserted transaction with ID: $id');
        final newTransaction = transaction.copyWith(id: id);
        _transactions.add(newTransaction);
        debugPrint('Added transaction to list: $newTransaction');
        _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        debugPrint('Preferred currency: ${_userFinances!.preferredCurrency}');
        double amount = transaction.amount;
        if (transaction.originalCurrency != null &&
            transaction.originalCurrency != _userFinances!.preferredCurrency) {
          amount = transaction.originalAmount ?? transaction.amount;
          debugPrint('Converted amount to $amount due to currency mismatch');
        }

        if (transaction.type == 'income') {
          _userFinances = UserFinances(
            id: _userFinances!.id,
            balance: _userFinances!.balance + amount,
            income: _userFinances!.income + amount,
            expense: _userFinances!.expense,
            preferredCurrency: _userFinances!.preferredCurrency,
          );
        } else {
          _userFinances = UserFinances(
            id: _userFinances!.id,
            balance: _userFinances!.balance - amount,
            income: _userFinances!.income,
            expense: _userFinances!.expense + amount,
            preferredCurrency: _userFinances!.preferredCurrency,
          );
        }
        await txn.update(
          'user_finances',
          _userFinances!.toMap(),
          where: 'id = ?',
          whereArgs: [_userFinances!.id],
        );
        debugPrint('Updated user_finances: ${_userFinances!.toMap()}');
      });
      debugPrint('Transaction list length: ${_transactions.length}');
      _applyDateFilter();
      groupTransactionsByDate();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.transaction((sqflite.Transaction txn) async {
      final oldTransaction = _transactions.firstWhere((t) => t.id == transaction.id);
      double oldAmount = oldTransaction.amount;
      String oldType = oldTransaction.type;

      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      _transactions[index] = transaction;
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      double newAmount = transaction.amount;
      if (transaction.originalCurrency != null &&
          transaction.originalCurrency != _userFinances!.preferredCurrency) {
        newAmount = transaction.originalAmount ?? transaction.amount;
      }

      double balance = _userFinances!.balance;
      double income = _userFinances!.income;
      double expense = _userFinances!.expense;
      if (oldType == 'income') {
        balance -= oldAmount;
        income -= oldAmount;
      } else {
        balance += oldAmount;
        expense -= oldAmount;
      }

      if (transaction.type == 'income') {
        balance += newAmount;
        income += newAmount;
      } else {
        balance -= newAmount;
        expense += newAmount;
      }

      _userFinances = UserFinances(
        id: _userFinances!.id,
        balance: balance,
        income: income,
        expense: expense,
        preferredCurrency: _userFinances!.preferredCurrency,
      );
      await txn.update(
        'user_finances',
        _userFinances!.toMap(),
        where: 'id = ?',
        whereArgs: [_userFinances!.id],
      );
    });
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((sqflite.Transaction txn) async {
      final transaction = _transactions.firstWhere(
            (t) => t.id == id,
        orElse: () => throw Exception('Transaction with ID $id not found'),
      );
      debugPrint(
          'Deleting transaction: ID: ${transaction.id}, Type: ${transaction.type}, Amount: ${transaction.amount}, Original Amount: ${transaction.originalAmount}, Original Currency: ${transaction.originalCurrency}');

      double amount = transaction.amount;
      debugPrint('Amount to adjust (in preferred currency): $amount');
      String type = transaction.type;

      int deletedCount = await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
      debugPrint('Deleted $deletedCount rows from database');

      _transactions.removeWhere((t) => t.id == id);
      debugPrint('Transactions remaining: ${_transactions.length}');

      double balance = _userFinances!.balance;
      double income = _userFinances!.income;
      double expense = _userFinances!.expense;
      if (type == 'income') {
        balance -= amount;
        income -= amount;
      } else {
        balance += amount;
        expense -= amount;
      }

      _userFinances = UserFinances(
        id: _userFinances!.id,
        balance: balance,
        income: income,
        expense: expense,
        preferredCurrency: _userFinances!.preferredCurrency,
      );
      await txn.update(
        'user_finances',
        _userFinances!.toMap(),
        where: 'id = ?',
        whereArgs: [_userFinances!.id],
      );
      debugPrint('Updated UserFinances after deletion: ${_userFinances!.toMap()}');
    });
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  void setCustomDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return;
    _customStartDate = start;
    _customEndDate = end;
    _selectedStartDate = start;
    _selectedEndDate = end;
    _dateFilter = 'Custom';
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  void setDateFromPicker(DateTime date) {
    _customStartDate = null;
    _customEndDate = null;
    _selectedStartDate = date;
    _setDateRangeForFilter();
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  void shiftDateRange(int direction) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (direction > 0) {
      // Check if the current end date is already at or beyond today
      if (_selectedEndDate != null) {
        // Special case for Monthly: Allow navigation to the current month
        if (_dateFilter == 'Monthly') {
          final newStartDate = DateTime(
            _selectedStartDate!.year,
            _selectedStartDate!.month + direction,
            1,
          );
          if (newStartDate.year == now.year && newStartDate.month == now.month) {
            // Allow navigation to the current month
          } else if (newStartDate.isAfter(today)) {
            return; // Prevent navigation to future months
          }
        }
        // Special case for Yearly: Allow navigation to the current year
        else if (_dateFilter == 'Yearly') {
          final newStartDate = DateTime(
            _selectedStartDate!.year + direction,
            1,
            1,
          );
          if (newStartDate.year == now.year) {
            // Allow navigation to the current year
          } else if (newStartDate.isAfter(today)) {
            return; // Prevent navigation to future years
          }
        }
        // For other filters, check the end date
        else if (!_selectedEndDate!.isBefore(today)) {
          return; // Prevent navigating forward if we're already at or past today
        }
      }
    }

    if (_dateFilter == 'Daily') {
      final newStartDate = _selectedStartDate!.add(Duration(days: direction));
      // Only allow the shift if the new date is not in the future
      if (direction > 0 && newStartDate.isAfter(today)) {
        return;
      }
      _selectedStartDate = newStartDate;
      _selectedEndDate = newStartDate;
    } else if (_dateFilter == 'Weekly') {
      final newEndDate = _selectedEndDate!.add(Duration(days: 7 * direction));
      if (direction > 0 && newEndDate.isAfter(today)) {
        return;
      }
      final newStartDate = newEndDate.subtract(const Duration(days: 6));
      _selectedStartDate = newStartDate;
      _selectedEndDate = newEndDate;
    } else if (_dateFilter == 'Monthly') {
      final newStartDate = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month + direction,
        1,
      );
      final newEndDate = DateTime(
        newStartDate.year,
        newStartDate.month + 1,
        0,
      );
      _selectedStartDate = newStartDate;
      _selectedEndDate = newEndDate;
    } else if (_dateFilter == '3 Months') {
      final newEndDate = _selectedEndDate!.add(Duration(days: 90 * direction)); // Approximate 3 months
      if (direction > 0 && newEndDate.isAfter(today)) {
        return;
      }
      final newStartDate = DateTime(
        newEndDate.year,
        newEndDate.month - 2,
        newEndDate.day,
      );
      _selectedStartDate = newStartDate;
      _selectedEndDate = newEndDate;
    } else if (_dateFilter == '6 Months') {
      final newEndDate = _selectedEndDate!.add(Duration(days: 180 * direction)); // Approximate 6 months
      if (direction > 0 && newEndDate.isAfter(today)) {
        return;
      }
      final newStartDate = DateTime(
        newEndDate.year,
        newEndDate.month - 5,
        newEndDate.day,
      );
      _selectedStartDate = newStartDate;
      _selectedEndDate = newEndDate;
    } else if (_dateFilter == 'Yearly') {
      final newStartDate = DateTime(
        _selectedStartDate!.year + direction,
        1,
        1,
      );
      final newEndDate = DateTime(
        newStartDate.year,
        12,
        31,
      );
      _selectedStartDate = newStartDate;
      _selectedEndDate = newEndDate;
    }

    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  void updateFilters({
    String? dateFilter,
    bool? filterExpense,
    bool? filterIncome,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dateFilter != null) {
      _dateFilter = dateFilter;
      _customStartDate = null;
      _customEndDate = null;
      _tempStartDate = null;

      // Reset dates to today based on the new filter
      if (_dateFilter == 'Daily') {
        _selectedStartDate = DateTime(today.year, today.month, today.day);
        _selectedEndDate = _selectedStartDate;
      } else if (_dateFilter == 'Weekly') {
        _selectedStartDate = today.subtract(Duration(days: today.weekday - 1)); // Start of the week (Monday)
        _selectedEndDate = today; // End on today
      } else if (_dateFilter == 'Monthly') {
        _selectedStartDate = DateTime(today.year, today.month, 1);
        _selectedEndDate = DateTime(today.year, today.month + 1, 0);
      } else if (_dateFilter == '3 Months') {
        _selectedStartDate = DateTime(today.year, today.month - 2, today.day); // Start 3 months ago on the same day
        _selectedEndDate = today; // End on today
      } else if (_dateFilter == '6 Months') {
        _selectedStartDate = DateTime(today.year, today.month - 5, today.day); // Start 6 months ago on the same day
        _selectedEndDate = today; // End on today
      } else if (_dateFilter == 'Yearly') {
        _selectedStartDate = DateTime(today.year, 1, 1);
        _selectedEndDate = DateTime(today.year, 12, 31);
      }
      _calendarDate = today;
    }

    // Update other filters if provided
    if (filterExpense != null) {
      _filterExpense = filterExpense;
    }
    if (filterIncome != null) {
      _filterIncome = filterIncome;
    }

    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  void _setDateRangeForFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    DateTime endDate;

    if (_selectedStartDate == null) {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = _selectedStartDate!;
    }

    switch (_dateFilter) {
      case 'Daily':
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate;
        break;
      case 'Weekly':
        startDate = startDate.subtract(Duration(days: startDate.weekday - 1)); // Start of the week
        endDate = startDate.add(const Duration(days: 6));
        if (endDate.isAfter(today)) {
          endDate = today;
          startDate = endDate.subtract(const Duration(days: 6));
        }
        break;
      case 'Monthly':
        startDate = DateTime(startDate.year, startDate.month, 1);
        endDate = DateTime(startDate.year, startDate.month + 1, 0);
        break;
      case '3 Months':
        endDate = today;
        startDate = DateTime(endDate.year, endDate.month - 2, endDate.day);
        break;
      case '6 Months':
        endDate = today;
        startDate = DateTime(endDate.year, endDate.month - 5, endDate.day);
        break;
      case 'Yearly':
        startDate = DateTime(startDate.year, 1, 1);
        endDate = DateTime(startDate.year, 12, 31);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
    }

    if (endDate.isAfter(today)) {
      endDate = today;
      startDate = _calculateStartDate(endDate);
    }

    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
  }

  DateTime _calculateStartDate(DateTime endDate) {
    switch (_dateFilter) {
      case 'Daily':
        return endDate;
      case 'Weekly':
        return endDate.subtract(const Duration(days: 6));
      case 'Monthly':
        return DateTime(endDate.year, endDate.month, 1);
      case '3 Months':
        return DateTime(endDate.year, endDate.month - 2, endDate.day);
      case '6 Months':
        return DateTime(endDate.year, endDate.month - 5, endDate.day);
      case 'Yearly':
        return DateTime(endDate.year, 1, 1);
      default:
        return DateTime(endDate.year, endDate.month, 1);
    }
  }

  void clearFilters() {
    _customStartDate = null;
    _customEndDate = null;
    _selectedStartDate = null;
    _selectedEndDate = null;
    _dateFilter = 'Monthly';
    _filterIncome = false;
    _filterExpense = true;
    _setDateRangeForFilter();
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  bool areFiltersApplied() {
    return _filterIncome || !_filterExpense || _dateFilter != 'Monthly' || _customStartDate != null;
  }

  void _applyDateFilter() {
    DateTime? startDate = _customStartDate ?? _selectedStartDate;
    DateTime? endDate = _customEndDate ?? _selectedEndDate;

    if (startDate == null || endDate == null) {
      final now = DateTime.now();
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
    }

    if (_dateFilter == 'Custom' && (_customStartDate == null || _customEndDate == null)) {
      final now = DateTime.now();
      startDate = DateTime(now.year, now.month - 1, now.day);
      endDate = now;
      _customStartDate = startDate;
      _customEndDate = endDate;
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
    }

    if (startDate.isAfter(endDate)) {
      final temp = startDate;
      startDate = endDate;
      endDate = temp;
      if (_dateFilter == 'Custom') {
        _customStartDate = startDate;
        _customEndDate = endDate;
      }
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
    }

    _filteredTransactions = _transactions.where((transaction) {
      final transactionDate = transaction.timestampAsDateTime;
      return transactionDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();

    if (_filterIncome && _filterExpense) {
      // Show all
    } else if (_filterIncome) {
      _filteredTransactions = _filteredTransactions.where((t) => t.type == 'income').toList();
    } else if (_filterExpense) {
      _filteredTransactions = _filteredTransactions.where((t) => t.type == 'expense').toList();
    } else {
      _filteredTransactions = [];
    }
  }

  void groupTransactionsByDate([BuildContext? context]) {
    _groupedTransactions.clear();
    _dateKeys.clear();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormat = DateFormat('dd.MM.yy');

    for (var transaction in _filteredTransactions) {
      final transactionDate = transaction.timestampAsDateTime;
      final transactionDay = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);

      String dateKey;
      if (transactionDay == today) {
        dateKey = context != null ? AppLocalizations.of(context)!.today : 'Today';
      } else if (transactionDay == yesterday) {
        dateKey = context != null ? AppLocalizations.of(context)!.yesterday : 'Yesterday';
      } else {
        dateKey = dateFormat.format(transactionDay);
      }

      if (!_groupedTransactions.containsKey(dateKey)) {
        _groupedTransactions[dateKey] = [];
      }
      _groupedTransactions[dateKey]!.add(transaction);
    }

    _dateKeys = _groupedTransactions.keys.toList();
    _dateKeys.sort((a, b) {
      DateTime dateA, dateB;
      if (a == (context != null ? AppLocalizations.of(context)!.today : 'Today')) {
        dateA = today;
      } else if (a == (context != null ? AppLocalizations.of(context)!.yesterday : 'Yesterday')) {
        dateA = yesterday;
      } else {
        dateA = dateFormat.parse(a);
      }

      if (b == (context != null ? AppLocalizations.of(context)!.today : 'Today')) {
        dateB = today;
      } else if (b == (context != null ? AppLocalizations.of(context)!.yesterday : 'Yesterday')) {
        dateB = yesterday;
      } else {
        dateB = dateFormat.parse(b);
      }

      return dateB.compareTo(dateA); // Sort descending
    });

    for (var dateKey in _dateKeys) {
      _groupedTransactions[dateKey]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> addCategory({required String name, required String type}) async {
    final db = await _dbHelper.database;
    final newCategory = Category(
      id: null, // Let SQLite auto-generate the ID
      name: name,
      type: type,
    );
    final id = await db.insert('categories', newCategory.toMap());
    final addedCategory = Category(
      id: id,
      name: name,
      type: type,
    );
    _categories.add(addedCategory);
    // Assign a random color to the new custom category
    _customCategoryColors[name.toLowerCase()] = _generateRandomColor();
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    try {
      // Fetch the category to get its name and type before deleting
      final categoryResult = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (categoryResult.isEmpty) {
        throw Exception('Category with ID $id not found');
      }

      final category = categoryResult.first;
      final categoryName = category['name'] as String;
      final categoryType = category['type'] as String;

      // Determine the fallback category based on the type
      final fallbackCategory = categoryType == 'income' ? 'other_income' : 'other_expense';

      // Fetch all transactions that use this category
      final transactions = await db.query(
        'transactions',
        where: 'custom_category_id = ?',
        whereArgs: [id],
      );

      // Update each transaction
      for (var transaction in transactions) {
        final transactionId = transaction['id'] as int;
        String newDescription = transaction['description'] as String? ?? '';
        if (newDescription.isNotEmpty) {
          newDescription += ' ($categoryName)';
        } else {
          newDescription = '($categoryName)';
        }

        // Update the transaction: set default_category to fallback and append to description
        await db.update(
          'transactions',
          {
            'default_category': fallbackCategory,
            'description': newDescription,
          },
          where: 'id = ?',
          whereArgs: [transactionId],
        );
      }

      // Delete the category (this will also set custom_category_id to NULL due to ON DELETE SET NULL)
      final deletedCount = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deletedCount == 0) {
        throw Exception('Category with ID $id not found');
      }

      // Update the in-memory list of categories
      _categories.removeWhere((category) => category.id == id);
      // Remove the color for the deleted category
      _customCategoryColors.remove(categoryName.toLowerCase());

      // Refresh transactions in memory to reflect the updates
      await loadData();

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  String getDateRangeDisplayText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final dateFormatFull = DateFormat('MMM dd, yyyy'); // For Daily and Custom
    final dateFormatShort = DateFormat('MMM dd'); // For Weekly, 3 Months, 6 Months

    if (_dateFilter == 'Yearly') {
      return '${_selectedStartDate!.year}';
    } else if (_dateFilter == 'Monthly') {
      final month = _selectedStartDate!.month;
      final year = _selectedStartDate!.year;
      return '${localizations.getShortMonthName(month)}, $year';
    } else if (_dateFilter == 'Daily') {
      return dateFormatFull.format(_selectedStartDate!);
    } else if (_dateFilter == 'Custom') {
      return '${dateFormatFull.format(_customStartDate!)} - ${dateFormatFull.format(_customEndDate!)}';
    } else {
      // Weekly, 3 Months, 6 Months
      return '${dateFormatShort.format(_selectedStartDate!)} - ${dateFormatShort.format(_selectedEndDate!)}';
    }
  }

  void shiftCalendarMonth(int direction) {
    _calendarDate = DateTime(
      _calendarDate.year,
      _calendarDate.month + direction,
      1,
    );
    notifyListeners();
  }

  void setDateFromCalendarTap(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Prevent selecting future dates
    if (date.isAfter(today)) {
      return; // Do nothing if the date is in the future
    }

    if (_dateFilter == 'Daily') {
      _selectedStartDate = date;
      _selectedEndDate = date;
    } else {
      // Switch to Custom mode
      _dateFilter = 'Custom';
      if (_tempStartDate == null) {
        _tempStartDate = date;
        _customStartDate = date;
        _customEndDate = date; // Temporarily set end date to start date
      } else {
        if (date.isBefore(_tempStartDate!)) {
          _customStartDate = date;
          _customEndDate = _tempStartDate;
        } else {
          _customStartDate = _tempStartDate;
          _customEndDate = date;
        }
        _tempStartDate = null; // Reset temp start date after setting range
      }
    }
    _applyDateFilter();
    groupTransactionsByDate();
    notifyListeners();
  }

  Color _generateRandomColor() {
    // Predefined colors in RGB format (same as in CategoryScreen and ReportsScreen)
    final List<Color> predefinedColors = [
      Color(0xFFEF5350), // food
      Color(0xFF42A5F5), // transport
      Color(0xFFAB47BC), // housing
      Color(0xFF26C6DA), // utilities
      Color(0xFFFFCA28), // entertainment
      Color(0xFF4CAF50), // healthcare
      Color(0xFFFF8A65), // education
      Color(0xFFD4E157), // shopping
      Color(0xFF90A4AE), // other_expense
      Color(0xFF66BB6A), // salary
      Color(0xFFF06292), // gift
      Color(0xFF29B6F6), // interest
      Color(0xFF78909C), // other_income
      Color(0xFFB0BEC5), // unknown (used in ReportsScreen)
    ];

    // Convert predefined colors to HSL for comparison
    List<List<double>> predefinedHSL = predefinedColors.map((color) {
      final r = color.red / 255.0;
      final g = color.green / 255.0;
      final b = color.blue / 255.0;
      final cMax = [r, g, b].reduce((a, b) => a > b ? a : b);
      final cMin = [r, g, b].reduce((a, b) => a < b ? a : b);
      final delta = cMax - cMin;

      double h = 0.0, s = 0.0, l = (cMax + cMin) / 2.0;

      if (delta != 0) {
        s = l > 0.5 ? delta / (2.0 - cMax - cMin) : delta / (cMax + cMin);
        if (cMax == r) {
          h = (g - b) / delta + (g < b ? 6.0 : 0.0);
        } else if (cMax == g) {
          h = (b - r) / delta + 2.0;
        } else if (cMax == b) {
          h = (r - g) / delta + 4.0;
        }
        h *= 60.0;
      }
      return [h, s, l];
    }).toList();

    // Generate a random color in HSL space and ensure it's not too similar
    Color randomColor;
    bool isTooSimilar;
    do {
      // Generate random hue (0-360), saturation (0.5-1.0), and lightness (0.4-0.6)
      final random = Random();
      final hue = random.nextDouble() * 360.0;
      final saturation = 0.5 + random.nextDouble() * 0.5; // 0.5 to 1.0
      final lightness = 0.4 + random.nextDouble() * 0.2; // 0.4 to 0.6

      // Convert HSL to RGB
      double r, g, b;
      if (saturation == 0) {
        r = g = b = lightness;
      } else {
        double hueToRgb(double p, double q, double t) {
          if (t < 0) t += 1.0;
          if (t > 1) t -= 1.0;
          if (t < 1 / 6) return p + (q - p) * 6.0 * t;
          if (t < 1 / 2) return q;
          if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6.0;
          return p;
        }

        final q = lightness < 0.5 ? lightness * (1.0 + saturation) : lightness + saturation - lightness * saturation;
        final p = 2.0 * lightness - q;
        r = hueToRgb(p, q, (hue / 360.0) + 1 / 3);
        g = hueToRgb(p, q, hue / 360.0);
        b = hueToRgb(p, q, (hue / 360.0) - 1 / 3);
      }

      randomColor = Color.fromRGBO(
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
        1.0,
      );

      // Convert the random color to HSL for comparison
      final rNorm = randomColor.red / 255.0;
      final gNorm = randomColor.green / 255.0;
      final bNorm = randomColor.blue / 255.0;
      final cMax = [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);
      final cMin = [rNorm, gNorm, bNorm].reduce((a, b) => a < b ? a : b);
      final delta = cMax - cMin;

      double h = 0.0, s = 0.0, l = (cMax + cMin) / 2.0;
      if (delta != 0) {
        s = l > 0.5 ? delta / (2.0 - cMax - cMin) : delta / (cMax + cMin);
        if (cMax == rNorm) {
          h = (gNorm - bNorm) / delta + (gNorm < bNorm ? 6.0 : 0.0);
        } else if (cMax == gNorm) {
          h = (bNorm - rNorm) / delta + 2.0;
        } else if (cMax == bNorm) {
          h = (rNorm - gNorm) / delta + 4.0;
        }
        h *= 60.0;
      }

      // Check if the random color is too similar to any predefined color
      isTooSimilar = false;
      for (var hsl in predefinedHSL) {
        final hueDiff = (h - hsl[0]).abs();
        final adjustedHueDiff = hueDiff > 180 ? 360 - hueDiff : hueDiff;
        final saturationDiff = (s - hsl[1]).abs();
        final lightnessDiff = (l - hsl[2]).abs();

        // Consider colors too similar if hue difference is less than 30 degrees,
        // and saturation and lightness differences are small
        if (adjustedHueDiff < 30 && saturationDiff < 0.2 && lightnessDiff < 0.1) {
          isTooSimilar = true;
          break;
        }
      }
    } while (isTooSimilar);

    return randomColor;
  }
}