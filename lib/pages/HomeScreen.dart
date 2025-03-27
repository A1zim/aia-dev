import 'package:flutter/material.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/notification_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/widgets/summary_card.dart';
import 'package:personal_finance/models/transaction.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
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
        NotificationService.showNotification(
          context,
          message: 'Failed to load summary: $e',
          isError: true,
        );
      }
    }
  }

  Future<List<Transaction>> _fetchTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      // Sort transactions by timestamp (newest first) and take the 10 most recent
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return transactions.take(10).toList();
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to load transactions: $e',
          isError: true,
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

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
      drawer: CustomDrawer(
        currentRoute: '/main',
        parentContext: context,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SummaryCard(
                      title: 'Income',
                      amount: '${currencyProvider.convertAmount(_totalIncome).toStringAsFixed(2)} $currencySymbol',
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      title: 'Expenses',
                      amount: '${currencyProvider.convertAmount(_totalExpenses).toStringAsFixed(2)} $currencySymbol',
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      title: 'Balance',
                      amount: '${currencyProvider.convertAmount(_balance).toStringAsFixed(2)} $currencySymbol',
                      color: Colors.blue,
                      icon: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(context, '/add_transaction');
                          if (result == true) {
                            setState(() {
                              _loadData();
                            });
                          }
                        },
                        style: AppButtonStyles.elevatedButton(context).copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        child: Text(
                          'Add Transaction',
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recents',
                    style: AppTextStyles.subheading(context),
                  ),
                ),
              ),
              FutureBuilder<List<Transaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: AppTextStyles.body(context).copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No transactions yet.',
                          style: AppTextStyles.body(context).copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  final transactions = snapshot.data!;
                  return Column(
                    children: transactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final transaction = entry.value;
                      return _buildTransactionTile(transaction, index == transactions.length - 1);
                    }).toList(),
                  );
                },
              ),
              // Add extra padding at the bottom to ensure the last transaction is fully visible
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);
    bool isIncome = transaction.type == 'income';

    return Card(
      elevation: 2,
      margin: EdgeInsets.fromLTRB(10, 6, 10, isLast ? 16 : 6),
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
          '${currencyProvider.convertAmount(transaction.amount).toStringAsFixed(2)} $currencySymbol',
          style: AppTextStyles.body(context).copyWith(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}