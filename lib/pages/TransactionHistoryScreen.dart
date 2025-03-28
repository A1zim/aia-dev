import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/generated/app_localizations.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  List<Transaction> _transactions = [];
  String _searchQuery = "";
  late String _filterType; // Use late initialization
  int? _expandedIndex;
  final int _pageSize = 20; // Number of transactions to fetch per page
  int _currentPage = 1; // Current page number
  bool _isLoadingMore = false; // Flag to prevent multiple simultaneous fetches
  bool _hasMoreTransactions = true; // Flag to check if there are more transactions to fetch
  final ScrollController _scrollController = ScrollController(); // Scroll controller for pagination

  @override
  void initState() {
    super.initState();
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the localized value of _filterType using the context
    _filterType = AppLocalizations.of(context)!.all;
    // Ensure this only runs once by checking if _transactions is empty
    if (_transactions.isEmpty) {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreTransactions) {
      // When the user scrolls to 80% of the list, fetch more transactions
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _transactions.clear();
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
        } else {
          _transactions.addAll(paginatedResponse.items);
        }
        _hasMoreTransactions = paginatedResponse.hasMore;
        _isLoadingMore = false;
        if (_hasMoreTransactions) {
          _currentPage++;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.transactionsLoadFailed(e.toString()),
              style: AppTextStyles.body(context),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

  Future<void> _deleteTransaction(int id, int index) async {
    final deletedTransaction = _transactions[index];
    bool shouldDelete = true;

    setState(() {
      _transactions.removeAt(index);
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });

    if (mounted) {
      final snackBar = SnackBar(
        content: Text(
          AppLocalizations.of(context)!.transactionDeleted,
          style: AppTextStyles.body(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          textColor: Colors.white,
          onPressed: () {
            shouldDelete = false;
            setState(() {
              _transactions.insert(index, deletedTransaction);
              if (_expandedIndex != null && _expandedIndex! >= index) {
                _expandedIndex = _expandedIndex! + 1;
              }
            });
          },
        ),
        duration: const Duration(seconds: 3),
      );

      await ScaffoldMessenger.of(context)
          .showSnackBar(snackBar)
          .closed
          .then((reason) {
        if (shouldDelete && reason != SnackBarClosedReason.action) {
          _apiService.deleteTransaction(id).catchError((e) {
            setState(() {
              _transactions.insert(index, deletedTransaction);
              if (_expandedIndex != null && _expandedIndex! >= index) {
                _expandedIndex = _expandedIndex! + 1;
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.deleteTransactionFailed(e.toString()),
                    style: AppTextStyles.body(context),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          });
        }
      });
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      _loadTransactions(reset: true); // Reset and reload transactions after edit
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
      _loadTransactions(reset: true); // Reload transactions with the new filter
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
    // Map the localized filter type back to its English value for comparison
    if (localizedFilterType == AppLocalizations.of(context)!.all) {
      return "all";
    } else if (localizedFilterType == AppLocalizations.of(context)!.expense) {
      return "expense";
    } else if (localizedFilterType == AppLocalizations.of(context)!.incomeFilter) {
      return "income";
    }
    return "all"; // Fallback
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
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    // Since filtering is now done server-side, we don't need to filter the transactions here
    List<Transaction> filteredTransactions = _transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.transactionHistory,
          style: AppTextStyles.heading(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkPrimary, AppColors.darkSecondary]
                  : [AppColors.lightPrimary, AppColors.lightSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
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
            _buildSearchAndFilterRow(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadTransactions(reset: true),
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: filteredTransactions.isEmpty
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
                  thumbVisibility: true, // Always show the scrollbar
                  thickness: 6.0, // Adjust thickness for better visibility
                  radius: const Radius.circular(3), // Rounded edges for the scrollbar
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredTransactions.length && _isLoadingMore) {
                        // Show a loading indicator at the bottom while fetching more transactions
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(
                          transaction, index, currencyProvider, currencySymbol);
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
                      _loadTransactions(reset: true); // Reload transactions with empty search
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
                  _loadTransactions(reset: true); // Reload transactions with new search query
                });
              },
              // Enable multilingual input for Russian and Kyrgyz
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
                                "${AppLocalizations.of(context)!.getCategoryName(transaction.category)} - ${transaction.timestamp.split("T")[0]}",
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpanded ? null : 0,
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
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.date,
                              transaction.timestamp.split("T")[0],
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