import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:personal_finance/models/currency_converter.dart'; // Add this import

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Transaction> _transactions = [];
  String _searchQuery = "";
  String _filterType = "All";
  int? _expandedIndex;
  String _currentCurrency = 'KGS'; // Add this field

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadCurrency(); // Add this method call
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen (in case currency changed)
    _loadCurrency();
    _loadTransactions();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyConverter.getPreferredCurrency();
    setState(() {
      _currentCurrency = currency;
    });
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
    bool shouldDelete = true; // Flag to determine if we should proceed with backend deletion

    // Remove the transaction from the UI
    setState(() {
      _transactions.removeAt(index);
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });

    // Show the SnackBar with an "Undo" option
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
            shouldDelete = false; // User tapped "Undo", so we won't delete from backend
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

      // Show the SnackBar and wait for it to be dismissed
      await ScaffoldMessenger.of(context)
          .showSnackBar(snackBar)
          .closed
          .then((reason) {
        // If the SnackBar was dismissed without "Undo" (e.g., timed out or page switched),
        // proceed with the backend deletion
        if (shouldDelete && reason != SnackBarClosedReason.action) {
          _apiService.deleteTransaction(id).catchError((e) {
            // If backend deletion fails, restore the transaction
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () => _showFilterModal(),
          ),
        ],
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
            _buildSearchBar(),
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
                    return _buildTransactionCard(transaction, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Removed unused variable 'isExpanded'
    final isIncome = transaction.type == 'income';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Dismissible(
        key: Key(transaction.id.toString()),
        direction: DismissDirection.horizontal,
        background: Container(
          padding: const EdgeInsets.only(left: 20),
          color: Colors.green,
          alignment: Alignment.centerLeft,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete, color: Colors.white),
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
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedIndex = index;
              } else {
                _expandedIndex = null;
              }
            });
          },
          title: Row(
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
                child: Text(
                  transaction.description,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FutureBuilder<String>(
                future: CurrencyConverter.formatWithPreferredCurrency(transaction.amount, 'KGS'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "${CurrencyConverter.formatWithCurrency(transaction.amount, _currentCurrency)}",
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    );
                  }
                  return Text(
                    snapshot.data ?? "${CurrencyConverter.formatWithCurrency(transaction.amount, _currentCurrency)}",
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  );
                }
              ),
            ],
          ),
          subtitle: Text(
            "${StringExtension(transaction.category).capitalize()} - ${transaction.timestamp.split("T")[0]}",
            style: AppTextStyles.body(context).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          children: [
            Padding(
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
                  FutureBuilder<String>(
                    future: CurrencyConverter.formatWithPreferredCurrency(transaction.amount),
                    builder: (context, snapshot) {
                      return _buildDetailRow(
                        "Amount",
                        snapshot.data ?? "${CurrencyConverter.formatWithCurrency(transaction.amount, _currentCurrency)}",
                        context,
                        valueColor: isIncome ? Colors.green : Colors.red,
                      );
                    }
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
          ],
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Filter Transactions",
                style: AppTextStyles.subheading(context),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _filterType,
                decoration: AppInputStyles.dropdown(context, labelText: 'Filter by Type'),
                items: ["All", "Income", "Expense"]
                    .map((type) => AppInputStyles.dropdownMenuItem(context, type, type))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _filterType = value!;
                  });
                  Navigator.pop(context);
                },
                style: AppInputStyles.dropdownProperties(context)['style'],
                dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
                icon: AppInputStyles.dropdownProperties(context)['icon'],
                menuMaxHeight: AppInputStyles.dropdownProperties(context)['menuMaxHeight'],
                borderRadius: AppInputStyles.dropdownProperties(context)['borderRadius'],
                elevation: AppInputStyles.dropdownProperties(context)['elevation'],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper function for capitalization
extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}