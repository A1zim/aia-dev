import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/widgets/summary_card.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart'; 
import 'package:personal_finance/models/currency_converter.dart'; // Add this import

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
  String _currentCurrency = 'KGS'; // Add this line

  @override
  void initState() {
    super.initState();
    _loadData();
    _userDataFuture = _fetchUserData();
    _loadCurrency(); // Add this method call
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen (in case currency changed)
    _loadCurrency();
    _loadData();
  }

  // Add this method
  Future<void> _loadCurrency() async {
    final currency = await CurrencyConverter.getPreferredCurrency();
    setState(() {
      _currentCurrency = currency;
    });
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppTextStyles.subheading(context),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.body(context),
              ),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                await _apiService.clearTokens();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text(
                'Logout',
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

  Widget _buildSummaryCards() {
    return Column(
      children: [
        FutureBuilder<String>(
          future: CurrencyConverter.formatWithPreferredCurrency(_totalIncome, 'KGS'),
          builder: (context, snapshot) {
            return SummaryCard(
              title: 'Income',
              amount: snapshot.data ?? 
                CurrencyConverter.formatWithCurrency(_totalIncome, _currentCurrency),
              color: Colors.green,
              icon: Icons.arrow_upward,
            );
          }
        ),
        const SizedBox(height: 12),
        FutureBuilder<String>(
          future: CurrencyConverter.formatWithPreferredCurrency(_totalExpenses, 'KGS'),
          builder: (context, snapshot) {
            return SummaryCard(
              title: 'Expenses',
              amount: snapshot.data ?? 
                CurrencyConverter.formatWithCurrency(_totalExpenses, _currentCurrency),
              color: Colors.red,
              icon: Icons.arrow_downward,
            );
          }
        ),
        const SizedBox(height: 12),
        FutureBuilder<String>(
          future: CurrencyConverter.formatWithPreferredCurrency(_balance, 'KGS'),
          builder: (context, snapshot) {
            return SummaryCard(
              title: 'Balance',
              amount: snapshot.data ?? 
                CurrencyConverter.formatWithCurrency(_balance, _currentCurrency),
              color: Colors.blue,
              icon: Icons.account_balance_wallet,
            );
          }
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      drawer: _buildDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummaryCards(), // Use the updated method
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
            // Reload data and currency when returning from add transaction
            await _loadCurrency();
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
        trailing: FutureBuilder<String>(
          future: CurrencyConverter.formatWithPreferredCurrency(transaction.amount, 'KGS'),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? CurrencyConverter.formatWithCurrency(transaction.amount, _currentCurrency),
              style: AppTextStyles.body(context).copyWith(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          }
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

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: FutureBuilder<Map<String, String>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          final nickname = snapshot.data?['nickname'] ?? 'User';
          final email = snapshot.data?['email'] ?? 'user@example.com';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimary, AppColors.darkSecondary]
                        : [AppColors.lightPrimary, AppColors.lightSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 50,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.wb_sunny : Icons.nightlight_round,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            size: 28,
                          ),
                          onPressed: () {
                            Provider.of<ThemeProvider>(context, listen: false)
                                .toggleTheme();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nickname,
                      style: AppTextStyles.subheading(context),
                    ),
                    Text(
                      email,
                      style: AppTextStyles.body(context).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.home,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Home',
                  style: AppTextStyles.body(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Transaction History',
                  style: AppTextStyles.body(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/history');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.bar_chart,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Reports',
                  style: AppTextStyles.body(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reports');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Settings',
                  style: AppTextStyles.body(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Logout',
                  style: AppTextStyles.body(context),
                ),
                onTap: _showLogoutDialog,
              ),
            ],
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}