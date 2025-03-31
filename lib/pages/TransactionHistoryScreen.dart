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
  String _searchQuery = "";
  late String _filterType;
  int? _expandedIndex;
  final int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreTransactions = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Map<String, List<Transaction>> _groupedTransactions = {};
  List<String> _dateKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.text = _searchQuery;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterType = AppLocalizations.of(context)!.all;
    if (_transactions.isEmpty) {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8 &&
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
      });
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final filterValue = _getFilterTypeValue(_filterType);
      final paginatedResponse = await _apiService.getTransactions(
        page: _currentPage,
        pageSize: _pageSize,
        type: filterValue,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        if (reset) {
          _transactions = paginatedResponse.items;
          _filteredTransactions = _applySearchFilter(_transactions);
        } else {
          _transactions.addAll(paginatedResponse.items);
          _filteredTransactions = _applySearchFilter(_transactions);
        }
        _hasMoreTransactions = paginatedResponse.hasMore;
        _isLoadingMore = false;
        if (_hasMoreTransactions) {
          _currentPage++;
        }
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

  List<Transaction> _applySearchFilter(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }
    return transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _groupTransactionsByDate() {
    _groupedTransactions.clear();
    _dateKeys.clear();

    // Set today as March 31, 2025
    final now = DateTime(2025, 3, 31);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1)); // March 30, 2025
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

  Future<void> _deleteTransaction(int id, int index) async {
    try {
      await _apiService.deleteTransaction(id);
      setState(() {
        _transactions.removeAt(index);
        _filteredTransactions = _applySearchFilter(_transactions);
        if (_expandedIndex == index) {
          _expandedIndex = null;
        } else if (_expandedIndex != null && _expandedIndex! > index) {
          _expandedIndex = _expandedIndex! - 1;
        }
        _groupTransactionsByDate();
      });
      // Show success notification after deletion
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.transactionDeleted,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.deleteTransactionFailed(e.toString()),
          isError: true,
        );
      }
      await _loadTransactions(reset: true);
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

  Future<bool> _confirmDeleteTransaction(int id, int index) async {
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
                          style: AppButtonStyles.textButton(context),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: AppTextStyles.body(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: AppButtonStyles.elevatedButton(context).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
      },
    );

    return confirmed ?? false;
  }

  void _cycleFilterType() {
    setState(() {
      if (_filterType == AppLocalizations.of(context)!.all) {
        _filterType = AppLocalizations.of(context)!.expense;
      } else if (_filterType == AppLocalizations.of(context)!.expense) {
        _filterType = AppLocalizations.of(context)!.incomeFilter;
      } else {
        _filterType = AppLocalizations.of(context)!.all;
      }
      _loadTransactions(reset: true);
    });
  }

  Color _getFilterTypeColor(String filterType) {
    final Map<String, Color> filterTypeColors = {
      AppLocalizations.of(context)!.all: const Color(0xFF78909C),
      AppLocalizations.of(context)!.incomeFilter: const Color(0xFF4CAF50),
      AppLocalizations.of(context)!.expense: const Color(0xFFEF5350),
    };
    return filterTypeColors[filterType] ?? Colors.grey.withOpacity(0.8);
  }

  String _getFilterTypeValue(String localizedFilterType) {
    if (localizedFilterType == AppLocalizations.of(context)!.all) {
      return "all";
    } else if (localizedFilterType == AppLocalizations.of(context)!.expense) {
      return "expense";
    } else if (localizedFilterType == AppLocalizations.of(context)!.incomeFilter) {
      return "income";
    }
    return "all";
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
                                text: 'AIA',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'Wallet',
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
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
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
            _buildSearchAndFilterRow(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadTransactions(reset: true),
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: _filteredTransactions.isEmpty
                    ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noTransactionsFound,
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                )
                    : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6.0,
                  radius: const Radius.circular(3),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: _dateKeys.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _dateKeys.length && _isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final dateKey = _dateKeys[index];
                      final transactions = _groupedTransactions[dateKey]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              dateKey,
                              style: AppTextStyles.subheading(context).copyWith(
                                fontSize: 16,
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

  Widget _buildSearchAndFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: _cycleFilterType,
                style: AppButtonStyles.elevatedButton(context).copyWith(
                  backgroundColor: WidgetStateProperty.all(_getFilterTypeColor(_filterType)),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                ),
                child: Text(
                  _filterType,
                  style: AppTextStyles.body(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 75,
            child: TextField(
              controller: _searchController,
              decoration: AppInputStyles.textField(context).copyWith(
                labelText: AppLocalizations.of(context)!.searchTransactions,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = "";
                      _searchController.clear();
                      _filteredTransactions = _applySearchFilter(_transactions);
                      _groupTransactionsByDate();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filteredTransactions = _applySearchFilter(_transactions);
                  _groupTransactionsByDate();
                });
              },
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index,
      CurrencyProvider currencyProvider, String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedIndex == index;
    final isIncome = transaction.type == 'income';
    final convertedAmount = _convertAmount(
      transaction.amount,
      transaction.originalAmount,
      transaction.originalCurrency,
      currencyProvider.currency,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Dismissible(
          key: Key(transaction.id.toString()),
          direction: DismissDirection.horizontal,
          background: Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.only(left: 20),
            alignment: Alignment.centerLeft,
            child: const Icon(Icons.edit, color: Colors.green, size: 30),
          ),
          secondaryBackground: Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.red, size: 30),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              final confirmed = await _confirmDeleteTransaction(transaction.id, index);
              if (confirmed) {
                await _deleteTransaction(transaction.id, index);
              }
              return false;
            } else if (direction == DismissDirection.startToEnd) {
              _editTransaction(transaction);
              return false;
            }
            return false;
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIndex = null;
                } else {
                  _expandedIndex = index;
                }
              });
            },
            child: Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                                transaction.description,
                                style: AppTextStyles.body(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                AppLocalizations.of(context)!.getCategoryName(transaction.category),
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
                              transaction.description,
                              context,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.category,
                              AppLocalizations.of(context)!.getCategoryName(transaction.category),
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context,
      {Color? valueColor}) {
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