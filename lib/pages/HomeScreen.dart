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

// Placeholder for PaginatedResponse if not defined
class PaginatedResponse<T> {
  final List<T> items;
  final bool hasMore;

  PaginatedResponse({required this.items, required this.hasMore});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Transaction> _transactions = [];
  late Map<String, String> _userData = {
    'nickname': 'User',
    'email': 'user@example.com',
  };
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  bool _isLoading = false;
  int? _expandedIndex; // Track the expanded transaction

  // Track the positions of the cards (0: Top, 1: Bottom Left, 2: Bottom Right)
  List<String> _cardOrder = ['balance', 'income', 'expense'];

  // Map to store the current position index of each card
  Map<String, int> _cardPositions = {
    'balance': 0, // Top
    'income': 1,  // Bottom Left
    'expense': 2, // Bottom Right
  };

  // Track animation state
  bool _isAnimating = false;
  late AnimationController _animationController;

  // Define default categories for translation check
  static const List<String> _defaultCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
    'salary', 'gift', 'interest', 'other_income',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
      setState(() {
        _isAnimating = status == AnimationStatus.forward || status == AnimationStatus.reverse;
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      debugPrint('Error fetching user data: $e');
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

  Future<bool> _onWillPop() async {
    SystemNavigator.pop();
    return false;
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await _apiService.deleteTransaction(id);
      await _refreshData();
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.transactionDeleted,
      );
    } catch (e) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.deleteTransactionFailed(e.toString()),
        isError: true,
      );
    }
  }

  Future<bool> _confirmDeleteTransaction(int id) async {
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
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: const TextStyle(color: Colors.white),
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

  void _onCardTap(String cardType) {
    if (_isAnimating) return;

    setState(() {
      int currentIndex = _cardPositions[cardType]!;

      if (currentIndex == 0) return;

      // Find the card currently at position 0 (top)
      String topCard = _cardPositions.entries.firstWhere((entry) => entry.value == 0).key;

      // Swap positions
      _cardPositions[cardType] = 0;
      _cardPositions[topCard] = currentIndex;

      // Update card order
      _cardOrder = ['balance', 'income', 'expense']..sort((a, b) => _cardPositions[a]!.compareTo(_cardPositions[b]!));

      _animationController.forward(from: 0);
    });
  }

  // Navigate to a hypothetical CategoriesScreen and refresh data if a category was deleted
  Future<void> _navigateToCategoriesScreen() async {
    // Replace CategoriesScreen with your actual category management screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(), // Hypothetical screen
      ),
    );
    // Check if a category was deleted (assuming the screen returns a result)
    if (result is Map<String, dynamic> && result['categoryDeleted'] == true) {
      await _refreshData();
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.categoryDeleted,
      );
    }
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
                                    text: 'MON',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ey',
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

                // Summary Cards Section with Animation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 210, // Height to accommodate top card (100) + spacing (10) + bottom cards (100)
                    child: Stack(
                      children: [
                        // Balance Card
                        _buildAnimatedCard(
                          cardType: 'balance',
                          title: AppLocalizations.of(context)!.balance,
                          amount: _balance.toStringAsFixed(2),
                          currencySymbol: currencySymbol,
                          color: const Color(0xFF006699),
                          icon: Icons.account_balance_wallet,
                        ),
                        // Income Card
                        _buildAnimatedCard(
                          cardType: 'income',
                          title: AppLocalizations.of(context)!.income,
                          amount: _totalIncome.toStringAsFixed(2),
                          currencySymbol: currencySymbol,
                          color: const Color(0xFF009966),
                          icon: Icons.arrow_downward,
                        ),
                        // Expense Card
                        _buildAnimatedCard(
                          cardType: 'expense',
                          title: AppLocalizations.of(context)!.expenses,
                          amount: _totalExpenses.toStringAsFixed(2),
                          currencySymbol: currencySymbol,
                          color: const Color(0xFF990033),
                          icon: Icons.arrow_upward,
                        ),
                      ],
                    ),
                  ),
                ),

                // Add Transaction Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 132,
                    height: 47,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(),
                          ),
                        );
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.addTransaction,
                        style: const TextStyle(
                          fontSize: 16,
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

                // Transactions with Expand/Collapse and Actions
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
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: Column(
                      children: _transactions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final transaction = entry.value;
                        return _buildTransactionTile(transaction, index == _transactions.length - 1, index);
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

  Widget _buildAnimatedCard({
    required String cardType,
    required String title,
    required String amount,
    required String currencySymbol,
    required Color color,
    required IconData icon,
  }) {
    double getAdaptiveFontSize(String amountText) {
      final length = amountText.length;
      if (length > 12) return 14.0;
      if (length > 10) return 16.0;
      if (length > 8) return 18.0;
      if (length > 6) return 20.0;
      return 22.0;
    }

    final fontSize = getAdaptiveFontSize(amount);
    final position = _cardPositions[cardType]!;
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 16.0;
    final topCardWidth = screenWidth - 2 * padding;
    final bottomCardWidth = (screenWidth - 3 * padding) / 2;

    // Define positions
    double left, top, width, height;
    if (position == 0) {
      left = 0;
      top = 0;
      width = topCardWidth;
      height = 100;
    } else if (position == 1) {
      left = 0;
      top = 110;
      width = bottomCardWidth;
      height = 100;
    } else {
      left = bottomCardWidth + padding;
      top = 110;
      width = bottomCardWidth;
      height = 100;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: _isAnimating ? null : () => _onCardTap(cardType),
        child: Card(
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
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              size: 20,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            amount,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currencySymbol,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction, bool isLast, int index) {
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
    final isExpanded = _expandedIndex == index;

    // Determine if the category is default or custom and get the display name
    String getCategoryDisplayName() {
      final categoryName = transaction.category ?? 'other_${transaction.type}';
      if (_defaultCategories.contains(categoryName)) {
        return AppLocalizations.of(context)!.getCategoryName(categoryName).capitalize();
      }
      return categoryName.capitalize();
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.fromLTRB(10, 6, 10, isLast ? 16 : 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
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
                            getCategoryDisplayName(),
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${transaction.description ?? ''} - ${transaction.timestamp.split("T")[0]}',
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${convertedAmount.toStringAsFixed(2)} $currencySymbol',
                      style: AppTextStyles.body(context).copyWith(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionScreen(transaction: transaction),
                              ),
                            );
                            if (result is Map<String, dynamic> && result['success'] == true) {
                              NotificationService.showNotification(
                                context,
                                message: result['message'],
                              );
                              await _refreshData();
                              setState(() => _expandedIndex = null);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.editTransaction,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final confirmDelete = await _confirmDeleteTransaction(transaction.id);
                            if (confirmDelete) {
                              await _deleteTransaction(transaction.id);
                              setState(() => _expandedIndex = null);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.white),
                          ),
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
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}

// Hypothetical CategoriesScreen placeholder
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder. Replace with your actual category management screen.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Simulate category deletion
            Navigator.pop(context, {'categoryDeleted': true});
          },
          child: const Text('Delete Category (Simulation)'),
        ),
      ),
    );
  }
}