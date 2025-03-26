import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/widgets/summary_card.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/widgets/drawer.dart'; // Import the CustomDrawer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Transaction>> _transactionsFuture;
  late Future<Map<String, String>> _userDataFuture;

  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _userDataFuture = _fetchUserData();
  }

  void _loadData() {
    _transactionsFuture = _fetchTransactions();
    _fetchSummaryData();
  }

  Future<Map<String, String>> _fetchUserData() async {
    try {
      final userData = await _apiService.getUserData();
      return {
        'nickname': userData['nickname'] ?? 'User',
        'email': userData['email'] ?? 'user@example.com',
      };
    } catch (e) {
      return {
        'nickname': 'User',
        'email': 'user@example.com',
      };
    }
  }

  Future<void> _fetchSummaryData() async {
    try {
      final summary = await _apiService.getFinancialSummary();
      setState(() {
        _totalIncome = summary['total_income']?.toDouble() ?? 0.0;
        _totalExpenses = summary['total_expense']?.toDouble() ?? 0.0;
        _balance = summary['balance']?.toDouble() ?? 0.0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load summary: $e',
              style: AppTextStyles.body(context),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<List<Transaction>> _fetchTransactions() async {
    try {
      return await _apiService.getTransactions();
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
      return [];
    }
  }

  // Map currency codes to their symbols
  String _getCurrencySymbol(String currency) {
    const symbols = {
      'KGS': 'KGS ',
      'USD': '\$',
      'EUR': '€',
      'INR': '₹',
    };
    return symbols[currency] ?? '$currency ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _getCurrencySymbol(currencyProvider.currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personal Finance',
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
      drawer: const CustomDrawer(currentRoute: '/home'), // Use CustomDrawer
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SummaryCard(
                  title: 'Income',
                  amount: '$currencySymbol${currencyProvider.convertAmount(_totalIncome).toStringAsFixed(2)}',
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  title: 'Expenses',
                  amount: '$currencySymbol${currencyProvider.convertAmount(_totalExpenses).toStringAsFixed(2)}',
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  title: 'Balance',
                  amount: '$currencySymbol${currencyProvider.convertAmount(_balance).toStringAsFixed(2)}',
                  color: Colors.blue,
                  icon: Icons.account_balance_wallet,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadData();
                });
              },
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              child: FutureBuilder<List<Transaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: AppTextStyles.body(context).copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No transactions yet.',
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    );
                  }

                  final transactions = snapshot.data!;
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionTile(transaction);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_transaction');
          if (result == true) {
            setState(() {
              _loadData();
            });
          }
        },
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        child: Icon(
          Icons.add,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _getCurrencySymbol(currencyProvider.currency);
    bool isIncome = transaction.type == 'income';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          StringExtension(transaction.category).capitalize(),
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${transaction.description} - ${transaction.timestamp.split("T")[0]}',
          style: AppTextStyles.body(context).copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '$currencySymbol${currencyProvider.convertAmount(transaction.amount).toStringAsFixed(2)}',
          style: AppTextStyles.body(context).copyWith(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _showTransactionActions(context, transaction),
      ),
    );
  }

  void _showTransactionActions(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Transaction Actions",
            style: AppTextStyles.subheading(context),
          ),
          content: Text(
            "What would you like to do?",
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () {
                Navigator.pop(context);
                _editTransaction(transaction);
              },
              child: Text(
                "Edit",
                style: AppTextStyles.body(context),
              ),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteTransaction(transaction.id);
              },
              child: Text(
                "Delete",
                style: AppTextStyles.body(context).copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      setState(() {
        _loadData();
      });
    }
  }

  Future<void> _deleteTransaction(int transactionId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Transaction",
          style: AppTextStyles.subheading(context),
        ),
        content: Text(
          "Are you sure you want to delete this transaction?",
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: AppTextStyles.body(context),
            ),
          ),
          TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: AppTextStyles.body(context).copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        await _apiService.deleteTransaction(transactionId);
        setState(() {
          _loadData();
        });
      } catch (e) {
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
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}