import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart'; // Import the Transaction model
import 'package:personal_finance/theme/styles.dart'; // Import the styles file

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
  int? _expandedIndex; // Track the currently expanded card

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
    setState(() {
      _transactions.removeAt(index);
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });

    // Show SnackBar with Undo option
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction deleted',
            style: AppTextStyles.body(context),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _transactions.insert(index, deletedTransaction);
                if (_expandedIndex != null && _expandedIndex! >= index) {
                  _expandedIndex = _expandedIndex! + 1;
                }
              });
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    try {
      await _apiService.deleteTransaction(id);
    } catch (e) {
      // If deletion fails, revert the UI change
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
    final isExpanded = _expandedIndex == index;
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
            // Swipe left to delete
            await _deleteTransaction(transaction.id, index);
            return false; // Prevent immediate dismissal since we handle it manually
          } else if (direction == DismissDirection.startToEnd) {
            // Swipe right to edit
            _editTransaction(transaction);
            return false; // Prevent dismissal since we're navigating
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
              Text(
                "\$${transaction.amount.toStringAsFixed(2)}",
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
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
                  _buildDetailRow(
                    "Amount",
                    "\$${transaction.amount.toStringAsFixed(2)}",
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
                decoration: AppInputStyles.dropdown(context),
                items: ["All", "Income", "Expense"].map((String type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: AppTextStyles.body(context),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterType = value!;
                  });
                  Navigator.pop(context);
                },
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