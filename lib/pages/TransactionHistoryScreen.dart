import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:personal_finance/localization/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        final bodyStyle = AppTextStyles.body(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.failedToLoadTransactions,
              style: bodyStyle,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(
    int id,
    int index,
    AppLocalizations localizations,
    TextStyle bodyStyle,
    Color errorColor,
  ) async {
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
          localizations.transactionDeleted,
          style: bodyStyle,
        ),
        backgroundColor: errorColor,
        action: SnackBarAction(
          label: localizations.undo,
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
                    localizations.failedToDeleteTransaction,
                    style: bodyStyle,
                  ),
                  backgroundColor: errorColor,
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

  Future<bool> _confirmDeleteTransaction(
    int id,
    int index,
    AppLocalizations localizations,
  ) async {
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
                    localizations.deleteTransaction,
                    style: AppTextStyles.subheading(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.confirmDeleteTransaction,
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
                            localizations.cancel,
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
                            localizations.confirm,
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
    final localizations = AppLocalizations.of(context);
    final bodyStyle = AppTextStyles.body(context);
    final errorColor = Theme.of(context).colorScheme.error;
    List<Transaction> filteredTransactions = _transactions.where((transaction) {
      final matchesSearch =
          transaction.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _filterType == localizations.all || transaction.type == _filterType.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.transactionHistory,
          style: AppTextStyles.heading(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () => _showFilterModal(localizations),
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
            _buildSearchBar(localizations),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTransactions,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          localizations.noTransactionsFound,
                          style: bodyStyle.copyWith(
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
                            transaction,
                            index,
                            localizations,
                            bodyStyle,
                            errorColor,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: AppInputStyles.textField(context).copyWith(
          labelText: localizations.searchTransactions,
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

  Widget _buildTransactionCard(
    Transaction transaction,
    int index,
    AppLocalizations localizations,
    TextStyle bodyStyle,
    Color errorColor,
  ) {
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
            final confirmed = await _confirmDeleteTransaction(
              transaction.id,
              index,
              localizations,
            );
            if (confirmed) {
              await _deleteTransaction(
                transaction.id,
                index,
                localizations,
                bodyStyle,
                errorColor,
              );
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
                  style: bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "\$${transaction.amount.toStringAsFixed(2)}",
                style: bodyStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          subtitle: Text(
            "${_getCategoryTranslation(transaction.category, localizations)} - ${transaction.timestamp.split("T")[0]}",
            style: bodyStyle.copyWith(
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
                    localizations.description,
                    transaction.description,
                    bodyStyle,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    localizations.category,
                    _getCategoryTranslation(transaction.category, localizations),
                    bodyStyle,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    localizations.amount,
                    "\$${transaction.amount.toStringAsFixed(2)}",
                    bodyStyle,
                    isDark,
                    valueColor: isIncome ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    localizations.type,
                    _getTypeTranslation(transaction.type, localizations),
                    bodyStyle,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    localizations.date,
                    transaction.timestamp.split("T")[0],
                    bodyStyle,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    TextStyle bodyStyle,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: bodyStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: bodyStyle.copyWith(
              color: valueColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterModal(AppLocalizations localizations) {
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
                localizations.filterTransactions,
                style: AppTextStyles.subheading(context),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _filterType,
                decoration: AppInputStyles.dropdown(
                  context,
                  labelText: localizations.filterByType,
                ),
                items: [
                  localizations.all,
                  localizations.income,
                  localizations.expense,
                ].map((type) => AppInputStyles.dropdownMenuItem(context, type, type)).toList(),
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

  String _getCategoryTranslation(String category, AppLocalizations localizations) {
    switch (category) {
      case 'food':
        return localizations.food;
      case 'transport':
        return localizations.transport;
      case 'housing':
        return localizations.housing;
      case 'utilities':
        return localizations.utilities;
      case 'entertainment':
        return localizations.entertainment;
      case 'healthcare':
        return localizations.healthcare;
      case 'education':
        return localizations.education;
      case 'shopping':
        return localizations.shopping;
      case 'other_expense':
        return localizations.otherExpense;
      case 'salary':
        return localizations.salary;
      case 'gift':
        return localizations.gift;
      case 'interest':
        return localizations.interest;
      case 'other_income':
        return localizations.otherIncome;
      default:
        return localizations.unknown;
    }
  }

  String _getTypeTranslation(String type, AppLocalizations localizations) {
    switch (type) {
      case 'income':
        return localizations.income;
      case 'expense':
        return localizations.expense;
      default:
        return localizations.unknown;
    }
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}