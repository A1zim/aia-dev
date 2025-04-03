import 'package:flutter/material.dart';
import 'package:aia_wallet/pages/AddTransactionScreen.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  Set<int> _expandedIndices = {};
  final int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreTransactions = true;
  final ScrollController _scrollController = ScrollController();

  bool _filterIncome = false;
  bool _filterExpense = true; // Default: expense active

  // Date filter variables
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _dateFilter = 'Last Month'; // Default filter for dropdown

  Map<String, List<Transaction>> _groupedTransactions = {};
  List<String> _dateKeys = [];

  // Define default categories for translation check
  static const List<String> _defaultCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
    'salary', 'gift', 'interest', 'other_income',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreTransactions) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _transactions.clear();
        _filteredTransactions.clear();
        _currentPage = 1;
        _hasMoreTransactions = true;
        _isLoadingMore = false;
        _expandedIndices.clear();
      });
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      String? typeFilter;
      if (_filterIncome && _filterExpense) {
        typeFilter = 'all';
      } else if (_filterIncome) {
        typeFilter = 'income';
      } else if (_filterExpense) {
        typeFilter = 'expense';
      }

      final paginatedResponse = await _apiService.getTransactions(
        page: _currentPage,
        pageSize: _pageSize,
        type: typeFilter,
      );

      setState(() {
        if (reset) {
          _transactions = paginatedResponse.items;
        } else {
          _transactions.addAll(paginatedResponse.items);
        }
        _hasMoreTransactions = paginatedResponse.hasMore;
        _isLoadingMore = false;
        if (_hasMoreTransactions) {
          _currentPage++;
        }
        _applyDateFilter();
        _groupTransactionsByDate();
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.transactionsLoadFailed(e.toString()),
          isError: true,
        );
      }
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreTransactions) return;
    await _loadTransactions();
  }

  void _applyDateFilter() {
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    if (_dateFilter == 'Custom' && _customStartDate != null && _customEndDate != null) {
      startDate = _customStartDate;
      endDate = _customEndDate;
    } else {
      switch (_dateFilter) {
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 6));
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
      }
    }

    selectedStartDate = startDate;
    selectedEndDate = endDate;

    if (startDate != null) {
      _filteredTransactions = _transactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction.timestamp.split('T')[0]);
        return transactionDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            transactionDate.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    } else {
      _filteredTransactions = List.from(_transactions);
    }
  }

  void _groupTransactionsByDate() {
    _groupedTransactions.clear();
    _dateKeys.clear();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormat = DateFormat('dd.MM.yy');

    for (var transaction in _filteredTransactions) {
      final dateStr = transaction.timestamp.split("T")[0];
      final transactionDate = DateTime.parse(dateStr);
      final transactionDay = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);

      String dateKey;
      if (transactionDay == today) {
        dateKey = AppLocalizations.of(context)!.today;
      } else if (transactionDay == yesterday) {
        dateKey = AppLocalizations.of(context)!.yesterday;
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
      if (a == AppLocalizations.of(context)!.today) {
        dateA = today;
      } else if (a == AppLocalizations.of(context)!.yesterday) {
        dateA = yesterday;
      } else {
        dateA = dateFormat.parse(a);
      }

      if (b == AppLocalizations.of(context)!.today) {
        dateB = today;
      } else if (b == AppLocalizations.of(context)!.yesterday) {
        dateB = yesterday;
      } else {
        dateB = dateFormat.parse(b);
      }

      return dateB.compareTo(dateA);
    });

    for (var dateKey in _dateKeys) {
      _groupedTransactions[dateKey]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await _apiService.deleteTransaction(id);
      await _loadTransactions(reset: true);
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.transactionDeleted,
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.deleteTransactionFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result is Map<String, dynamic> && result['success'] == true) {
      await _loadTransactions(reset: true);
      NotificationService.showNotification(
        context,
        message: result['message'],
      );
    }
  }

  Future<bool> _confirmDeleteTransaction(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.lightSurface, AppColors.lightBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteTransaction,
                    style: AppTextStyles.subheading(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.deleteTransactionConfirm,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
              primary: AppColors.darkAccent,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
            )
                : const ColorScheme.light(
              primary: AppColors.lightAccent,
              onPrimary: Colors.white,
              surface: AppColors.lightSurface,
              onSurface: AppColors.lightTextPrimary,
            ),
            dialogBackgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        _dateFilter = 'Custom';
        _applyDateFilter();
        _groupTransactionsByDate();
      });
    }
  }

  bool _areFiltersApplied() {
    return _customStartDate != null ||
        _customEndDate != null ||
        selectedStartDate != null ||
        selectedEndDate != null ||
        _dateFilter != 'Last Month';
  }

  void _clearFilters() {
    setState(() {
      _customStartDate = null;
      _customEndDate = null;
      selectedStartDate = null;
      selectedEndDate = null;
      _dateFilter = 'Last Month';
      _applyDateFilter();
      _groupTransactionsByDate();
    });
  }

  double _convertAmount(double amountInKGS, double? originalAmount, String? originalCurrency, String targetCurrency) {
    if (originalAmount != null && originalCurrency != null && originalCurrency == targetCurrency) {
      return originalAmount;
    }
    try {
      final rate = _currencyApiService.getConversionRate('KGS', targetCurrency);
      return amountInKGS * rate;
    } catch (e) {
      print('Error converting amount: $e');
      return amountInKGS;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.normal,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.transactionHistory,
                  style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadTransactions(reset: true),
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: _filteredTransactions.isEmpty
                    ? Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.noTransactionsFound,
                          style: AppTextStyles.body(context).copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6.0,
                  radius: const Radius.circular(3),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: _dateKeys.length + 1 + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildFilterSection();
                      }
                      if (index == _dateKeys.length + 1 && _isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final dateIndex = index - 1;
                      final dateKey = _dateKeys[dateIndex];
                      final transactions = _groupedTransactions[dateKey]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              dateKey,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          ...transactions.asMap().entries.map((entry) {
                            final transactionIndex = _filteredTransactions.indexOf(entry.value);
                            return _buildTransactionCard(
                              entry.value,
                              transactionIndex,
                              currencyProvider,
                              currencySymbol,
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateLabel = selectedStartDate != null ? dateFormat.format(selectedStartDate!) : 'Start';
    final endDateLabel = selectedEndDate != null ? dateFormat.format(selectedEndDate!) : 'End';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurface, AppColors.darkBackground]
                  : [AppColors.lightSurface, AppColors.lightBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (!_filterExpense && _filterIncome) {
                              _filterExpense = true;
                            } else {
                              _filterExpense = !_filterExpense;
                            }
                            _loadTransactions(reset: true);
                          });
                        },
                        child: Container(
                          width: 90,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _filterExpense
                                ? const Color(0xFFEF5350).withOpacity(0.8)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 18,
                                color: _filterExpense
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations!.expense,
                                style: TextStyle(
                                  color: _filterExpense
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_filterExpense && !_filterIncome) {
                              _filterIncome = true;
                            } else {
                              _filterIncome = !_filterIncome;
                            }
                            _loadTransactions(reset: true);
                          });
                        },
                        child: Container(
                          width: 90,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _filterIncome
                                ? const Color(0xFF4CAF50).withOpacity(0.8)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: 18,
                                color: _filterIncome
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations!.income,
                                style: TextStyle(
                                  color: _filterIncome
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_areFiltersApplied())
                    IconButton(
                      icon: Icon(Icons.clear, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                      onPressed: _clearFilters,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _dateFilter,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.dateRange,
                  labelStyle: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : Colors.grey[300]!,
                    ),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'Last 7 Days', child: Text(AppLocalizations.of(context)!.lastWeek)),
                  DropdownMenuItem(value: 'Last Month', child: Text(AppLocalizations.of(context)!.lastMonth)),
                  DropdownMenuItem(value: 'Last 3 Months', child: Text(AppLocalizations.of(context)!.last3Months)),
                  DropdownMenuItem(value: 'Custom', child: Text(AppLocalizations.of(context)!.custom)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _dateFilter = value;
                      if (value != 'Custom') {
                        _customStartDate = null;
                        _customEndDate = null;
                        _applyDateFilter();
                        _groupTransactionsByDate();
                      } else {
                        _selectDateRange();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _dateFilter == 'Custom' ? _selectDateRange : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations!.startDate,
                                  style: AppTextStyles.body(context).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  startDateLabel,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _dateFilter == 'Custom' ? _selectDateRange : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations!.endDate,
                                  style: AppTextStyles.body(context).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  endDateLabel,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index, CurrencyProvider currencyProvider, String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedIndices.contains(index);
    final isIncome = transaction.type == 'income';
    final convertedAmount = _convertAmount(
      transaction.amount,
      transaction.originalAmount,
      transaction.originalCurrency,
      currencyProvider.currency,
    );

    // Determine if the category is default or custom and get the display name
    String getCategoryDisplayName() {
      final categoryName = transaction.category ?? 'other_${transaction.type}';
      if (_defaultCategories.contains(categoryName)) {
        return AppLocalizations.of(context)!.getCategoryName(categoryName).capitalize();
      }
      return categoryName.capitalize();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedIndices.remove(index);
            } else {
              _expandedIndices.add(index);
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description ?? 'No description',
                            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            getCategoryDisplayName(),
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${convertedAmount.toStringAsFixed(2)} $currencySymbol",
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          AppLocalizations.of(context)!.description,
                          transaction.description ?? 'No description',
                          context,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.category,
                          getCategoryDisplayName(),
                          context,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.amount,
                          "${convertedAmount.toStringAsFixed(2)} $currencySymbol",
                          context,
                          valueColor: isIncome ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.type,
                          transaction.type == 'income'
                              ? AppLocalizations.of(context)!.income
                              : AppLocalizations.of(context)!.expense,
                          context,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.date,
                          DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction.timestamp)),
                          context,
                        ),
                        if (transaction.originalCurrency != null && transaction.originalAmount != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildDetailRow(
                              'Original',
                              '${transaction.originalAmount!.toStringAsFixed(2)} ${transaction.originalCurrency}',
                              context,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _editTransaction(transaction),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.editTransaction,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final confirmDelete = await _confirmDeleteTransaction(transaction.id);
                                if (confirmDelete) {
                                  await _deleteTransaction(transaction.id);
                                  setState(() => _expandedIndices.remove(index));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.delete,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: AppTextStyles.label(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              color: valueColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}