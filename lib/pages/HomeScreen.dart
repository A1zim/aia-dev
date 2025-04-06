import 'package:flutter/material.dart';
import 'package:aia_wallet/pages/AddTransactionScreen.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../utils/scaling.dart'; // Import the Scaling utility

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  Map<String, String> _userData = {
    'nickname': 'User',
    'email': 'user@example.com',
  };
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  bool _isLoading = false;
  int? _expandedIndex;

  // Card positions (0: Top, 1: Bottom Left, 2: Bottom Right)
  List<String> _cardOrder = ['balance', 'income', 'expense'];
  Map<String, int> _cardPositions = {
    'balance': 0,
    'income': 1,
    'expense': 2,
  };

  bool _isAnimating = false;
  late AnimationController _animationController;

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
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await Future.delayed(Duration.zero); // Ensure provider is initialized
      setState(() {
        _transactions = transactionProvider.transactions;
        _totalIncome = transactionProvider.userFinances?.income ?? 0.0;
        _totalExpenses = transactionProvider.userFinances?.expense ?? 0.0;
        _balance = transactionProvider.userFinances?.balance ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.failedToLoadData(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.loadData(); // Refresh data from database
      setState(() {
        _transactions = transactionProvider.transactions;
        _totalIncome = transactionProvider.userFinances?.income ?? 0.0;
        _totalExpenses = transactionProvider.userFinances?.expense ?? 0.0;
        _balance = transactionProvider.userFinances?.balance ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.failedToLoadData(e.toString()),
        isError: true,
      );
    }
  }

  Future<bool> _onWillPop() async {
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
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
              border: Border.all(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.exitApp,
                    style: AppTextStyles.subheading(context),
                  ),
                  SizedBox(height: Scaling.scalePadding(8)),
                  Text(
                    AppLocalizations.of(context)!.exitAppConfirm,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Scaling.scalePadding(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
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

    if (confirmed == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.deleteTransaction(id);
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
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
              border: Border.all(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteTransaction,
                    style: AppTextStyles.subheading(context),
                  ),
                  SizedBox(height: Scaling.scalePadding(8)),
                  Text(
                    AppLocalizations.of(context)!.deleteTransactionConfirm,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Scaling.scalePadding(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Scaling.scalePadding(12),
                              horizontal: Scaling.scalePadding(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
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

  void _onCardTap(String cardType) {
    if (_isAnimating) return;

    setState(() {
      int currentIndex = _cardPositions[cardType]!;

      if (currentIndex == 0) return;

      String topCard = _cardPositions.entries.firstWhere((entry) => entry.value == 0).key;

      _cardPositions[cardType] = 0;
      _cardPositions[topCard] = currentIndex;

      _cardOrder = ['balance', 'income', 'expense']..sort((a, b) => _cardPositions[a]!.compareTo(_cardPositions[b]!));

      _animationController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = currencyProvider.currency == 'KGS'
        ? 'Сом'
        : NumberFormat.simpleCurrency(name: currencyProvider.currency).currencySymbol;
    final logoPath = themeProvider.getLogoPath(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                  padding: EdgeInsets.symmetric(
                    horizontal: Scaling.scalePadding(16.0),
                    vertical: Scaling.scalePadding(10.0),
                  ),
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  child: SafeArea(
                    child: Row(
                      children: [
                        Image.asset(
                          logoPath,
                          height: Scaling.scale(40),
                          width: Scaling.scale(40),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
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
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
                  child: SizedBox(
                    height: Scaling.scale(210), // Scale the height of the card stack
                    child: Stack(
                      children: [
                        _buildAnimatedCard(
                          cardType: 'balance',
                          title: AppLocalizations.of(context)!.balance,
                          amount: currencyProvider.convertAmount(_balance).toStringAsFixed(2),
                          currencySymbol: currencySymbol,
                          color: const Color(0xFF006699),
                          icon: Icons.account_balance_wallet,
                        ),
                        _buildAnimatedCard(
                          cardType: 'income',
                          title: AppLocalizations.of(context)!.income,
                          amount: currencyProvider.convertAmount(_totalIncome).toStringAsFixed(2),
                          currencySymbol: currencySymbol,
                          color: const Color(0xFF009966),
                          icon: Icons.arrow_downward,
                        ),
                        _buildAnimatedCard(
                          cardType: 'expense',
                          title: AppLocalizations.of(context)!.expenses,
                          amount: currencyProvider.convertAmount(_totalExpenses).toStringAsFixed(2),
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
                  padding: EdgeInsets.symmetric(horizontal: Scaling.scalePadding(16.0)),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - Scaling.scale(132), // Scale the width
                    height: Scaling.scale(47), // Scale the height
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/add_transaction',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Scaling.scale(15)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Scaling.scalePadding(24),
                          vertical: Scaling.scalePadding(4),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.addTransaction,
                        style: TextStyle(
                          fontSize: Scaling.scaleFont(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Recents Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Scaling.scalePadding(16.0)),
                  child: Column(
                    children: [
                      Divider(
                        color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                        thickness: 1,
                      ),
                      SizedBox(height: Scaling.scalePadding(8)),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.recents,
                          style: AppTextStyles.subheading(context),
                        ),
                      ),
                      SizedBox(height: Scaling.scalePadding(8)),
                    ],
                  ),
                ),

                // Transactions with Expand/Collapse and Actions
                if (_transactions.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
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
                    padding: EdgeInsets.only(bottom: Scaling.scalePadding(80.0)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final isLast = index == _transactions.length - 1;
                        return _buildTransactionTile(transaction, isLast, index);
                      },
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
      if (length > 12) return Scaling.scaleFont(14.0);
      if (length > 10) return Scaling.scaleFont(16.0);
      if (length > 8) return Scaling.scaleFont(18.0);
      if (length > 6) return Scaling.scaleFont(20.0);
      return Scaling.scaleFont(22.0);
    }

    final fontSize = getAdaptiveFontSize(amount);
    final position = _cardPositions[cardType]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = Scaling.scalePadding(16.0);
    final topCardWidth = screenWidth - 2 * padding;
    final bottomCardWidth = (screenWidth - 3 * padding) / 2;

    double left, top, width, height;
    if (position == 0) {
      left = 0;
      top = 0;
      width = topCardWidth;
      height = Scaling.scale(100);
    } else if (position == 1) {
      left = 0;
      top = Scaling.scale(110);
      width = bottomCardWidth;
      height = Scaling.scale(100);
    } else {
      left = bottomCardWidth + padding;
      top = Scaling.scale(110);
      width = bottomCardWidth;
      height = Scaling.scale(100);
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
            borderRadius: BorderRadius.circular(Scaling.scale(5)),
          ),
          color: color,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Scaling.scale(5)),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(Scaling.scalePadding(8.0)),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Scaling.scalePadding(10),
                  vertical: Scaling.scalePadding(8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(Scaling.scale(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: Scaling.scale(8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: Scaling.scaleIcon(20),
                          color: Colors.white.withOpacity(0.9),
                        ),
                        SizedBox(width: Scaling.scalePadding(4)),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: Scaling.scaleFont(14),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Scaling.scalePadding(4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        SizedBox(width: Scaling.scalePadding(4)),
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
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencySymbol = currencyProvider.currency == 'KGS'
        ? 'Сом'
        : NumberFormat.simpleCurrency(name: currencyProvider.currency).currencySymbol;
    bool isIncome = transaction.type == 'income';
    final convertedAmount = currencyProvider.convertAmount(
      transaction.originalAmount != null &&
          transaction.originalCurrency != null &&
          transaction.originalCurrency == 'KGS'
          ? transaction.originalAmount!
          : transaction.amount,
    );
    final isExpanded = _expandedIndex == index;

    String getCategoryDisplayName() {
      final categoryName = transaction.getCategory(transactionProvider);
      if (_defaultCategories.contains(categoryName)) {
        return AppLocalizations.of(context)!.getCategoryName(categoryName).capitalize();
      }
      return categoryName.capitalize();
    }

    String formatTimestamp() {
      return DateFormat('yyyy-MM-dd').format(transaction.timestampAsDateTime);
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.fromLTRB(
        Scaling.scalePadding(10),
        Scaling.scalePadding(6),
        Scaling.scalePadding(10),
        isLast ? Scaling.scalePadding(16) : Scaling.scalePadding(6),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
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
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Scaling.scalePadding(16),
                  vertical: Scaling.scalePadding(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: Scaling.scale(24),
                      backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                        size: Scaling.scaleIcon(24),
                      ),
                    ),
                    SizedBox(width: Scaling.scalePadding(12)),
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
                            '${transaction.description ?? ''} - ${formatTimestamp()}',
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: Scaling.scaleFont(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: Scaling.scalePadding(8)),
                    Text(
                      '${convertedAmount.toStringAsFixed(2)} $currencySymbol',
                      style: AppTextStyles.body(context).copyWith(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: Scaling.scaleFont(16),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      size: Scaling.scaleIcon(24),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: Scaling.scalePadding(16.0),
                      vertical: Scaling.scalePadding(8.0),
                    ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: Scaling.scalePadding(16),
                              vertical: Scaling.scalePadding(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.editTransaction,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        ElevatedButton(
                          onPressed: () async {
                            final confirmDelete = await _confirmDeleteTransaction(transaction.id!);
                            if (confirmDelete) {
                              await _deleteTransaction(transaction.id!);
                              setState(() => _expandedIndex = null);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: Scaling.scalePadding(16),
                              vertical: Scaling.scalePadding(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
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