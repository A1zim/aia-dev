import 'package:flutter/material.dart';
import 'package:aia_wallet/pages/AddTransactionScreen.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/widgets/drawer.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'dart:io'; // For SystemNavigator.pop()

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(initialPage: 0);

  late List<Transaction> _transactions = [];
  late Map<String, String> _userData = {
    'nickname': 'User',
    'email': 'user@example.com',
  };
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUserData(),
      _fetchTransactions(),
      _fetchSummaryData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await _apiService.getUserData();
      setState(() {
        _userData = {
          'nickname': userData['nickname'] ?? 'User',
          'email': userData['email'] ?? 'user@example.com',
        };
      });
    } catch (e) {
      // Keep default user data if fetch fails
    }
  }

  Future<void> _fetchSummaryData() async {
    try {
      final summary = await _apiService.getFinancialSummary();
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final currentCurrency = currencyProvider.currency;

      final totalIncomeInKGS = summary['total_income']?.toDouble() ?? 0.0;
      final totalExpensesInKGS = summary['total_expense']?.toDouble() ?? 0.0;
      final balanceInKGS = summary['balance']?.toDouble() ?? 0.0;

      setState(() {
        _totalIncome = _convertAmount(totalIncomeInKGS, null, null, currentCurrency);
        _totalExpenses = _convertAmount(totalExpensesInKGS, null, null, currentCurrency);
        _balance = _convertAmount(balanceInKGS, null, null, currentCurrency);
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.summaryLoadFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final paginatedResponse = await _apiService.getTransactions(pageSize: 20);
      setState(() {
        _transactions = paginatedResponse.items;
        _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.transactionsLoadFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchTransactions(), _fetchSummaryData()]);
    setState(() => _isLoading = false);
  }

  double _convertAmount(double amountInKGS, double? originalAmount, String? originalCurrency, String targetCurrency) {
    if (originalAmount != null && originalCurrency != null && originalCurrency == targetCurrency) {
      return originalAmount;
    }
    try {
      final rate = _currencyApiService.getConversionRate('KGS', targetCurrency);
      return amountInKGS * rate;
    } catch (e) {
      debugPrint('Error converting amount: $e');
      return amountInKGS;
    }
  }

  // Handle back button press to exit the app
  Future<bool> _onWillPop() async {
    // Exit the app when the back button is pressed
    SystemNavigator.pop();
    return false; // Prevent default back navigation
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);
    final logoPath = themeProvider.getLogoPath(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(
          currentRoute: '/main',
          parentContext: context,
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Icon(
                            Icons.menu,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                      ],
                    ),
                  ),
                ),

                // Summary Cards Section (unchanged)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            final page = _pageController.hasClients ? (_pageController.page ?? 0) : 0;
                            final cardIndex = page.round() % 3;
                            Color bgColor;
                            switch (cardIndex) {
                              case 0:
                                bgColor = const Color(0xFF004466);
                                break;
                              case 1:
                                bgColor = const Color(0xFF660022);
                                break;
                              case 2:
                                bgColor = const Color(0xFF006644);
                                break;
                              default:
                                bgColor = const Color(0xFF004466);
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          child: Transform.translate(
                            offset: const Offset(-20, 0),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 92,
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Transform.translate(
                            offset: const Offset(20, 0),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 92,
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Transform.translate(
                            offset: const Offset(-10, 0),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 82,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Transform.translate(
                            offset: const Offset(10, 0),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 82,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          width: MediaQuery.of(context).size.width - 82,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: null,
                            itemBuilder: (context, index) {
                              final cardIndex = index % 3;
                              switch (cardIndex) {
                                case 0:
                                  return _buildSummaryCard(
                                    title: AppLocalizations.of(context)!.balance,
                                    amount: _balance.toStringAsFixed(2),
                                    currencySymbol: currencySymbol,
                                    color: const Color(0xFF006699),
                                    icon: Icons.account_balance_wallet,
                                  );
                                case 1:
                                  return _buildSummaryCard(
                                    title: AppLocalizations.of(context)!.expenses,
                                    amount: _totalExpenses.toStringAsFixed(2),
                                    currencySymbol: currencySymbol,
                                    color: const Color(0xFF990033),
                                    icon: Icons.arrow_upward,
                                  );
                                case 2:
                                  return _buildSummaryCard(
                                    title: AppLocalizations.of(context)!.income,
                                    amount: _totalIncome.toStringAsFixed(2),
                                    currencySymbol: currencySymbol,
                                    color: const Color(0xFF009966),
                                    icon: Icons.arrow_downward,
                                  );
                                default:
                                  return Container();
                              }
                            },
                          ),
                        ),
                        Positioned(
                          left: 20,
                          child: GestureDetector(
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Icon(
                              Icons.arrow_left,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Icon(
                              Icons.arrow_right,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Button (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 132,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/add_transaction');
                        if (result is Map<String, dynamic> && result['success'] == true) {
                          NotificationService.showNotification(
                            context,
                            message: result['message'],
                          );
                          await _refreshData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        elevation: 0,
                      ),
                      child: const Text(
                        '+Add Transaction',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Recents Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Divider(
                        color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                        thickness: 1,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.recents,
                          style: AppTextStyles.subheading(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Transactions with bottom padding
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTransactions,
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80.0), // Add padding to ensure last transaction is visible
                    child: Column(
                      children: _transactions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final transaction = entry.value;
                        return _buildTransactionTile(transaction, index == _transactions.length - 1);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required String currencySymbol,
    required Color color,
    required IconData icon,
  }) {
    double amountValue;
    try {
      amountValue = double.parse(amount);
    } catch (e) {
      amountValue = 0.0;
    }

    double fontSize;
    if (amountValue >= 1000000) {
      fontSize = 20.0;
    } else if (amountValue >= 100000) {
      fontSize = 22.0;
    } else if (amountValue >= 10000) {
      fontSize = 24.0;
    } else if (amountValue >= 1000) {
      fontSize = 26.0;
    } else {
      fontSize = 28.0;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      color: color,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$amount $currencySymbol',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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

    final convertedAmount = _convertAmount(
      transaction.amount,
      transaction.originalAmount,
      transaction.originalCurrency,
      currencyProvider.currency,
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.fromLTRB(10, 6, 10, isLast ? 16 : 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
          StringExtension(AppLocalizations.of(context)!.getCategoryName(transaction.category)).capitalize(),
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
          '${convertedAmount.toStringAsFixed(2)} $currencySymbol',
          style: AppTextStyles.body(context).copyWith(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/transaction_details',
            arguments: transaction,
          );
          if (result == true) {
            await _refreshData();
          }
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}