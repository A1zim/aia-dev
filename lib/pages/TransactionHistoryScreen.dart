import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';

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
  String _filterType = "All";
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load transactions: $e',
              style: AppTextStyles.body(context),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
          'Transaction deleted',
          style: AppTextStyles.body(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Undo',
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
                    'Failed to delete transaction: $e',
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
      _loadTransactions();
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
                    'Delete Transaction',
                    style: AppTextStyles.subheading(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete this transaction?',
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
                            'Cancel',
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
                            'Confirm',
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

  // Method to cycle through filter types
  void _cycleFilterType() {
    setState(() {
      if (_filterType == "All") {
        _filterType = "Expense";
      } else if (_filterType == "Expense") {
        _filterType = "Income";
      } else {
        _filterType = "All";
      }
    });
  }

  // Add a method to get a color for each filter type
  Color _getFilterTypeColor(String filterType) {
    final Map<String, Color> filterTypeColors = {
      'All': const Color(0xFF78909C), // Blue Grey for All
      'Income': const Color(0xFF4CAF50), // Green for Income
      'Expense': const Color(0xFFEF5350), // Red for Expense
    };
    return filterTypeColors[filterType] ?? Colors.grey.withOpacity(0.8);
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
      return amountInKGS; // Fallback to KGS if conversion fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    List<Transaction> filteredTransactions = _transactions.where((transaction) {
      final matchesSearch =
      transaction.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _filterType == "All" || transaction.type == _filterType.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transaction History",
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
                onRefresh: _loadTransactions,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: filteredTransactions.isEmpty
                    ? Center(
                  child: Text(
                    "No transactions found",
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return _buildTransactionCard(
                        transaction, index, currencyProvider, currencySymbol);
                  },
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
          // Filter button (25% width)
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
          // Search bar (75% width)
          Expanded(
            flex: 75,
            child: TextField(
              decoration: AppInputStyles.textField(context).copyWith(
                labelText: 'Search Transactions',
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
                });
              },
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
                                "${StringExtension(transaction.category).capitalize()} - ${transaction.timestamp.split("T")[0]}",
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
                              "Description",
                              transaction.description,
                              context,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              "Category",
                              StringExtension(transaction.category).capitalize(),
                              context,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              "Amount",
                              "${convertedAmount.toStringAsFixed(2)} $currencySymbol",
                              context,
                              valueColor: isIncome ? Colors.green : Colors.red,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              "Type",
                              StringExtension(transaction.type).capitalize(),
                              context,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              "Date",
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

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}