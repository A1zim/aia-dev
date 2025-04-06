import 'dart:async';
import 'package:aia_wallet/pages/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/transaction_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:intl/intl.dart';
import 'package:aia_wallet/utils/scaling.dart'; // Import Scaling utility

import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  Map<String, dynamic> _reportsData = {
    "categorySpending": <String, double>{},
    "monthlySpending": <String, double>{},
    "total": 0.0,
  };
  Map<String, dynamic> _cachedReportsData = {
    "categorySpending": <String, double>{},
    "monthlySpending": <String, double>{},
    "total": 0.0,
  };
  List<Map<String, dynamic>> selectedCategories = [];
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];
  List<Map<String, dynamic>> incomeCategories = [];
  int _currentPage = 0;
  String? _selectedCategory;
  String? _selectedMonth;
  bool _isLoading = false;
  bool _showLoadingOverlay = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loadingFadeAnimation;
  late AnimationController _radiusAnimationController;
  late Animation<double> _selectRadiusAnimation;
  late AnimationController _valueAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _detailsAnimationController;
  late Animation<double> _detailsFadeAnimation;
  late Animation<Offset> _detailsSlideAnimation;
  late AnimationController _disappearAnimationController;
  late Animation<double> _disappearAnimation;
  Map<String, Animation<double>> _valueAnimations = {};
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;
  bool _isCategorySpendingEmpty = true;
  bool _isMonthlySpendingEmpty = true;
  bool _shouldShowNoDataForCategorySpending = false;
  bool _shouldShowNoDataForMonthlySpending = false;
  Map<String, AnimationController> _disappearingControllers = {};
  Map<String, Animation<double>> _disappearingAnimations = {};
  Map<String, double> _disappearingValues = {};

  // Date filter state variables
  String _dateFilter = 'Monthly'; // Default to "Monthly"
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  DateTime? _tempStartDate; // For custom range selection in calendar
  DateTime _calendarDate = DateTime.now(); // For calendar dialog

  static const List<String> _defaultCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
    'salary', 'gift', 'interest', 'other_income',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, now.month, 1);
    _selectedEndDate = DateTime(now.year, now.month + 1, 0);
    _calendarDate = now;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _radiusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectRadiusAnimation = Tween<double>(begin: Scaling.scale(50.0), end: Scaling.scale(70.0)).animate(
      CurvedAnimation(parent: _radiusAnimationController, curve: Curves.easeInOut),
    );

    _valueAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: Scaling.scale(50.0), end: Scaling.scale(60.0)), weight: 50.0),
      TweenSequenceItem(tween: Tween<double>(begin: Scaling.scale(60.0), end: Scaling.scale(50.0)), weight: 50.0),
    ]).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _detailsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _detailsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _detailsAnimationController, curve: Curves.easeInOut),
    );
    _detailsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _detailsAnimationController, curve: Curves.easeInOut),
    );

    _disappearAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _disappearAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: -0.1), weight: 70.0),
      TweenSequenceItem(tween: Tween<double>(begin: -0.1, end: 0.0), weight: 30.0),
    ]).animate(
      CurvedAnimation(parent: _disappearAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      _scrollPosition = _scrollController.offset;
    });

    _loadCategories();
    _fetchData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _radiusAnimationController.dispose();
    _valueAnimationController.dispose();
    _pulseAnimationController.dispose();
    _detailsAnimationController.dispose();
    _disappearAnimationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _disappearingControllers.values.forEach((controller) => controller.dispose());
    _disappearingControllers.clear();
    _disappearingAnimations.clear();
    _disappearingValues.clear();
    super.dispose();
  }

  void _loadCategories() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    setState(() {
      allCategories = [];
      final seenNames = <String>{};

      final defaultCategories = _defaultCategories.map((name) => {
        'id': null,
        'name': name,
        'type': ['salary', 'gift', 'interest', 'other_income'].contains(name) ? 'income' : 'expense',
      }).toList();

      for (var category in defaultCategories) {
        seenNames.add(category['name']!);
        allCategories.add(category);
      }

      for (var category in transactionProvider.categories) {
        if (!seenNames.contains(category.name)) {
          allCategories.add({
            'id': category.id,
            'name': category.name,
            'type': category.type,
          });
          seenNames.add(category.name);
        }
      }

      expenseCategories = allCategories.where((cat) => cat['type'] == 'expense').toList();
      incomeCategories = allCategories.where((cat) => cat['type'] == 'income').toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _cachedReportsData = Map.from(_reportsData);
      _selectedCategory = null;
      _detailsAnimationController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isLoading) {
        setState(() {
          _showLoadingOverlay = true;
        });
      }
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final transactions = transactionProvider.transactions;

      final filteredTransactions = transactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction.timestamp.split('T')[0]);
        return (_selectedStartDate == null || transactionDate.isAfter(_selectedStartDate!.subtract(const Duration(days: 1)))) &&
            (_selectedEndDate == null || transactionDate.isBefore(_selectedEndDate!.add(const Duration(days: 1))));
      }).toList();

      final String selectedType = _currentPage == 0 ? 'expense' : 'income';
      final List<String> categoryNames = selectedCategories.isNotEmpty
          ? selectedCategories.map((cat) => cat['name'] as String).toList()
          : [];

      final Map<String, double> categorySpending = {};
      for (var transaction in filteredTransactions) {
        if (transaction.type != selectedType) continue;

        final category = transaction.getCategory(transactionProvider);
        if (categoryNames.isNotEmpty && !categoryNames.contains(category)) continue;

        final amount = _convertAmount(transaction);
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }

      final Map<String, double> monthlySpending = {};
      for (var transaction in filteredTransactions) {
        if (transaction.type != selectedType) continue;

        final category = transaction.getCategory(transactionProvider);
        if (categoryNames.isNotEmpty && !categoryNames.contains(category)) continue;

        final date = transaction.timestamp.substring(0, 7);
        final amount = _convertAmount(transaction);
        monthlySpending[date] = (monthlySpending[date] ?? 0) + amount;
      }

      final newReportsData = {
        "categorySpending": categorySpending,
        "monthlySpending": monthlySpending,
        "total": categorySpending.values.fold(0.0, (a, b) => a + b),
      };

      final previousSpending = _cachedReportsData["categorySpending"] as Map<String, double>;
      final newSpending = newReportsData["categorySpending"] as Map<String, double>;

      final removedCategories = previousSpending.keys.where((category) => !newSpending.containsKey(category)).toList();

      for (var category in removedCategories) {
        if (!_disappearingControllers.containsKey(category)) {
          final controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          );
          final initialValue = previousSpending[category] ?? 0.0;
          final animation = Tween<double>(begin: initialValue, end: 0.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );

          _disappearingControllers[category] = controller;
          _disappearingAnimations[category] = animation;
          _disappearingValues[category] = initialValue;

          controller.forward().then((_) {
            setState(() {
              _disappearingControllers.remove(category);
              _disappearingAnimations.remove(category);
              _disappearingValues.remove(category);
            });
            controller.dispose();
          });
        }
      }

      final allCategories = {...previousSpending.keys, ...newSpending.keys};
      final newValueAnimations = <String, Animation<double>>{};

      for (var category in allCategories) {
        final previousValue = previousSpending[category] ?? 0.0;
        final newValue = newSpending[category] ?? 0.0;
        newValueAnimations[category] = Tween<double>(
          begin: previousValue,
          end: newValue,
        ).animate(
          CurvedAnimation(
            parent: _valueAnimationController,
            curve: Curves.easeInOut,
          ),
        );
      }

      final bool newCategorySpendingEmpty = (newReportsData["categorySpending"] as Map<String, double>).isEmpty;
      final bool newMonthlySpendingEmpty = (newReportsData["monthlySpending"] as Map<String, double>).isEmpty;

      if (!_isCategorySpendingEmpty && newCategorySpendingEmpty) {
        await _disappearAnimationController.forward(from: 0.0);
        setState(() {
          _shouldShowNoDataForCategorySpending = true;
        });
      } else if (_isCategorySpendingEmpty && !newCategorySpendingEmpty) {
        setState(() {
          _shouldShowNoDataForCategorySpending = false;
        });
        _disappearAnimationController.reverse(from: 1.0).then((_) {
          _pulseAnimationController.forward(from: 0.0);
        });
      }

      if (!_isMonthlySpendingEmpty && newMonthlySpendingEmpty) {
        await _disappearAnimationController.forward(from: 0.0);
        setState(() {
          _shouldShowNoDataForMonthlySpending = true;
        });
      } else if (_isMonthlySpendingEmpty && !newMonthlySpendingEmpty) {
        setState(() {
          _shouldShowNoDataForMonthlySpending = false;
        });
        _disappearAnimationController.reverse(from: 1.0).then((_) {
          _pulseAnimationController.forward(from: 0.0);
        });
      }

      setState(() {
        _reportsData = newReportsData;
        _valueAnimations = newValueAnimations;
        _isLoading = false;
        _showLoadingOverlay = false;
        _isCategorySpendingEmpty = newCategorySpendingEmpty;
        _isMonthlySpendingEmpty = newMonthlySpendingEmpty;
      });

      _valueAnimationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showLoadingOverlay = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)?.failedToLoadData(e.toString()) ?? 'Failed to load data: $e',
        isError: true,
      );
    }
  }

  double _convertAmount(Transaction transaction) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final preferredCurrency = transactionProvider.userFinances?.preferredCurrency ?? 'KGS';

    if (transaction.originalAmount != null &&
        transaction.originalCurrency != null &&
        transaction.originalCurrency == preferredCurrency) {
      return transaction.originalAmount!;
    }

    final double amountInKGS = transaction.amount;
    final double exchangeRate = currencyProvider.exchangeRate;
    return currencyProvider.currency == 'KGS' ? amountInKGS : amountInKGS * exchangeRate;
  }

  String _getCurrencySymbol() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currency = transactionProvider.userFinances?.preferredCurrency ?? 'KGS';
    return currency == 'KGS' ? 'Сом' : NumberFormat.simpleCurrency(name: currency).currencySymbol;
  }

  Color _getChartColor(String category) {
    final Map<String, Color> categoryColors = {
      'food': const Color(0xFFEF5350),
      'transport': const Color(0xFF66BB6A),
      'housing': const Color(0xFF42A5F5),
      'utilities': const Color(0xFFFFCA28),
      'entertainment': const Color(0xFFAB47BC),
      'healthcare': const Color(0xFF26C6DA),
      'education': const Color(0xFFFFA726),
      'shopping': const Color(0xFFEC407A),
      'other_expense': const Color(0xFF8D6E63),
      'other_income': const Color(0xFF78909C),
      'salary': const Color(0xFF4CAF50),
      'gift': const Color(0xFFF06292),
      'interest': const Color(0xFF29B6F6),
      'unknown': const Color(0xFFB0BEC5),
    };
    return categoryColors[category.toLowerCase()]?.withOpacity(0.8) ?? Colors.grey.withOpacity(0.8);
  }

  Color _getBarColor(String month) {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.indigoAccent,
      Colors.limeAccent,
      Colors.deepPurpleAccent,
    ];
    final monthIndex = int.parse(month.split('-')[1]) - 1;
    return colors[monthIndex % colors.length].withOpacity(0.8);
  }

  String _getMonthLabel(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  double _calculateYInterval(Map<String, double> monthlySpending) {
    if (monthlySpending.isEmpty) return 100.0;
    final maxValue = monthlySpending.values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 100.0;
    final interval = maxValue / 5;
    return (interval / 100).ceil() * 100;
  }

  bool _areDateFiltersApplied() {
    return _dateFilter != 'Monthly' || _customStartDate != null || _customEndDate != null;
  }

  bool _areCategoryFiltersApplied() {
    return selectedCategories.isNotEmpty;
  }

  void _clearDateFilter() {
    setState(() {
      _dateFilter = 'Monthly';
      _tempStartDate = null;
      _customStartDate = null;
      _customEndDate = null;
      final now = DateTime.now();
      _selectedStartDate = DateTime(now.year, now.month, 1);
      _selectedEndDate = DateTime(now.year, now.month + 1, 0);
      _calendarDate = now;
    });
    _applyDateFilter();
    _fetchData();
  }

  void _clearCategoryFilter() {
    setState(() {
      selectedCategories.clear();
    });
    _fetchData();
  }

  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _getCategoryDisplayName(String category) {
    if (_defaultCategories.contains(category)) {
      return StringExtension(AppLocalizations.of(context)!.getCategoryName(category)).capitalize();
    }
    return StringExtension(category).capitalize();
  }

  void _updateDateFilter(String newFilter) {
    setState(() {
      _dateFilter = newFilter;
      _tempStartDate = null;
      _customStartDate = null;
      _customEndDate = null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (newFilter) {
        case 'Daily':
          _selectedStartDate = today;
          _selectedEndDate = today;
          break;
        case 'Weekly':
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          _selectedStartDate = startOfWeek;
          _selectedEndDate = today;
          break;
        case 'Monthly':
          _selectedStartDate = DateTime(now.year, now.month, 1);
          _selectedEndDate = DateTime(now.year, now.month + 1, 0);
          break;
        case '3 Months':
          _selectedStartDate = DateTime(now.year, now.month - 2, now.day);
          _selectedEndDate = today;
          break;
        case '6 Months':
          _selectedStartDate = DateTime(now.year, now.month - 5, now.day);
          _selectedEndDate = today;
          break;
        case 'Yearly':
          _selectedStartDate = DateTime(now.year, 1, 1);
          _selectedEndDate = DateTime(now.year, 12, 31);
          break;
        case 'Custom':
          break;
      }
    });
    _applyDateFilter();
    _fetchData();
  }

  void _shiftDateRange(int direction) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      if (_dateFilter == 'Daily') {
        final newStartDate = _selectedStartDate!.add(Duration(days: direction));
        if (direction > 0 && newStartDate.isAfter(today)) {
          return;
        }
        _selectedStartDate = newStartDate;
        _selectedEndDate = newStartDate;
      } else if (_dateFilter == 'Weekly') {
        final newEndDate = _selectedEndDate!.add(Duration(days: 7 * direction));
        if (direction > 0 && newEndDate.isAfter(today)) {
          return;
        }
        final newStartDate = newEndDate.subtract(const Duration(days: 6));
        _selectedStartDate = newStartDate;
        _selectedEndDate = newEndDate;
      } else if (_dateFilter == 'Monthly') {
        final newStartDate = DateTime(
          _selectedStartDate!.year,
          _selectedStartDate!.month + direction,
          1,
        );
        final newEndDate = DateTime(
          newStartDate.year,
          newStartDate.month + 1,
          0,
        );
        if (direction > 0 && newStartDate.isAfter(today)) {
          return;
        }
        _selectedStartDate = newStartDate;
        _selectedEndDate = newEndDate;
      } else if (_dateFilter == '3 Months') {
        final newEndDate = _selectedEndDate!.add(Duration(days: 90 * direction));
        if (direction > 0 && newEndDate.isAfter(today)) {
          return;
        }
        final newStartDate = DateTime(
          newEndDate.year,
          newEndDate.month - 2,
          newEndDate.day,
        );
        _selectedStartDate = newStartDate;
        _selectedEndDate = newEndDate;
      } else if (_dateFilter == '6 Months') {
        final newEndDate = _selectedEndDate!.add(Duration(days: 180 * direction));
        if (direction > 0 && newEndDate.isAfter(today)) {
          return;
        }
        final newStartDate = DateTime(
          newEndDate.year,
          newEndDate.month - 5,
          newEndDate.day,
        );
        _selectedStartDate = newStartDate;
        _selectedEndDate = newEndDate;
      } else if (_dateFilter == 'Yearly') {
        final newStartDate = DateTime(
          _selectedStartDate!.year + direction,
          1,
          1,
        );
        final newEndDate = DateTime(
          newStartDate.year,
          12,
          31,
        );
        if (direction > 0 && newStartDate.year > today.year) {
          return;
        }
        _selectedStartDate = newStartDate;
        _selectedEndDate = newEndDate;
      }
    });

    _applyDateFilter();
    _fetchData();
  }

  void _setDateFromCalendarTap(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isAfter(today)) {
      return;
    }

    setState(() {
      if (_dateFilter == 'Daily') {
        _selectedStartDate = date;
        _selectedEndDate = date;
      } else {
        _dateFilter = 'Custom';
        if (_tempStartDate == null) {
          _tempStartDate = date;
          _customStartDate = date;
          _customEndDate = date;
        } else {
          if (date.isBefore(_tempStartDate!)) {
            _customStartDate = date;
            _customEndDate = _tempStartDate;
          } else {
            _customStartDate = _tempStartDate;
            _customEndDate = date;
          }
          _tempStartDate = null;
        }
      }
      _applyDateFilter();
      _fetchData();
    });
  }

  void _applyDateFilter() {
    if (_dateFilter == 'Custom' && _customStartDate != null && _customEndDate != null) {
      _selectedStartDate = _customStartDate;
      _selectedEndDate = _customEndDate;
    }
  }

  void _shiftCalendarMonth(int direction) {
    setState(() {
      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + direction, 1);
    });
  }

  String _getDateRangeDisplayText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (_selectedStartDate == null || _selectedEndDate == null) {
      return localizations.customDateRange ?? 'Select Date Range';
    }

    final shortMonthStart = localizations.getShortMonthName(_selectedStartDate!.month);
    final shortMonthEnd = localizations.getShortMonthName(_selectedEndDate!.month);
    final yearStart = _selectedStartDate!.year.toString();
    final yearEnd = _selectedEndDate!.year.toString();
    final dayStart = _selectedStartDate!.day.toString().padLeft(2, '0');
    final dayEnd = _selectedEndDate!.day.toString().padLeft(2, '0');

    switch (_dateFilter) {
      case 'Daily':
        return '$shortMonthStart $dayStart, $yearStart';
      case 'Weekly':
        return '$shortMonthStart $dayStart - $shortMonthEnd $dayEnd';
      case 'Monthly':
        return '$shortMonthStart, $yearStart';
      case '3 Months':
      case '6 Months':
        return '$shortMonthStart $dayStart - $shortMonthEnd $dayEnd';
      case 'Yearly':
        return yearStart;
      case 'Custom':
        return '$shortMonthStart $dayStart, $yearStart - $shortMonthEnd $dayEnd';
      default:
        return '$shortMonthStart $dayStart - $shortMonthEnd $dayEnd';
    }
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Builder(
        builder: (innerContext) => _CustomCalendarDialog(
          parentState: this,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    final currencySymbol = _getCurrencySymbol();

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Scaling.scalePadding(16.0),
                    vertical: Scaling.scalePadding(10.0),
                  ),
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  child: SafeArea(
                    child: Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: Scaling.scalePadding(8.0)),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.reportsAndInsights ?? 'Reports & Insights',
                      style: AppTextStyles.heading(context).copyWith(fontSize: Scaling.scaleFont(18)),
                    ),
                  ),
                ),
                Divider(
                  color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                  thickness: 1,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: Scaling.scale(110),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: Scaling.scale(100),
                                  width: MediaQuery.of(context).size.width - Scaling.scalePadding(32),
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: 2,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                      _fetchData();
                                    },
                                    itemBuilder: (context, index) {
                                      final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
                                      return _buildSummaryCard(
                                        title: index == 0 ? AppLocalizations.of(context)!.expenses : AppLocalizations.of(context)!.income,
                                        amount: total.toStringAsFixed(2),
                                        currencySymbol: currencySymbol,
                                        color: index == 0 ? const Color(0xFF990033) : const Color(0xFF009966),
                                        icon: index == 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                      );
                                    },
                                  ),
                                ),
                                if (_currentPage != 0)
                                  Positioned(
                                    left: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Icon(
                                        Icons.arrow_left,
                                        size: Scaling.scaleIcon(30),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (_currentPage != 1)
                                  Positioned(
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Icon(
                                        Icons.arrow_right,
                                        size: Scaling.scaleIcon(30),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: Scaling.scalePadding(20)),
                          _buildDateFilterSection(),
                          SizedBox(height: Scaling.scalePadding(20)),
                          _buildChartCard(
                            title: AppLocalizations.of(context)!.categoryWiseSpending,
                            child: _shouldShowNoDataForCategorySpending
                                ? _buildNoDataWidget(isDark: isDark)
                                : AnimatedBuilder(
                              animation: Listenable.merge([
                                _radiusAnimationController,
                                _valueAnimationController,
                                _pulseAnimationController,
                                _disappearAnimationController,
                                ..._disappearingAnimations.values,
                              ]),
                              builder: (context, child) {
                                final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
                                final List<PieChartSectionData> sections = [
                                  ...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"]
                                      .entries
                                      .map<PieChartSectionData>((entry) {
                                    final category = entry.key;
                                    final isSelected = _selectedCategory == category;
                                    final baseRadius = (Scaling.scale(50.0) * _disappearAnimation.value).clamp(0.0, Scaling.scale(50.0));
                                    final selectionRadius = isSelected ? _selectRadiusAnimation.value : baseRadius;
                                    final radius = isSelected ? selectionRadius + (_pulseAnimation.value - Scaling.scale(50.0)) : baseRadius;
                                    final animatedValue = _valueAnimations[category]?.value ?? 0.0;

                                    final percentage = total > 0 ? (animatedValue / total) * 100 : 0.0;

                                    double titlePositionOffset;
                                    double fontSize;
                                    if (percentage < 5) {
                                      titlePositionOffset = 0.8;
                                      fontSize = Scaling.scaleFont(10.0);
                                    } else if (percentage < 10) {
                                      titlePositionOffset = 0.65;
                                      fontSize = Scaling.scaleFont(11.0);
                                    } else {
                                      titlePositionOffset = 0.55;
                                      fontSize = isSelected ? Scaling.scaleFont(14.0) : Scaling.scaleFont(12.0);
                                    }

                                    // Truncate category name, but show the full amount
                                    final truncatedCategory = _truncateString(_getCategoryDisplayName(category), 15);
                                    final amountLabel = '${animatedValue.toStringAsFixed(2)} $currencySymbol';

                                    return PieChartSectionData(
                                      value: animatedValue > 0 ? animatedValue : 0.001,
                                      title: _selectedCategory == category ? "$truncatedCategory\n$amountLabel" : "",
                                      radius: radius,
                                      color: _getChartColor(category),
                                      titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                        fontSize: fontSize,
                                        shadows: isSelected
                                            ? [
                                          Shadow(
                                            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                                            blurRadius: Scaling.scale(4),
                                            offset: const Offset(2, 2),
                                          ),
                                        ]
                                            : null,
                                      ),
                                      showTitle: animatedValue > 0 && _selectedCategory == category,
                                      titlePositionPercentageOffset: titlePositionOffset,
                                    );
                                  }).toList(),
                                  ..._disappearingAnimations.entries.map<PieChartSectionData>((entry) {
                                    final category = entry.key;
                                    final isSelected = _selectedCategory == category;
                                    final baseRadius = (Scaling.scale(50.0) * _disappearAnimation.value).clamp(0.0, Scaling.scale(50.0));
                                    final selectionRadius = isSelected ? _selectRadiusAnimation.value : baseRadius;
                                    final radius = isSelected ? selectionRadius + (_pulseAnimation.value - Scaling.scale(50.0)) : baseRadius;
                                    final animatedValue = entry.value.value;

                                    final percentage = total > 0 ? (animatedValue / total) * 100 : 0.0;

                                    double titlePositionOffset;
                                    double fontSize;
                                    if (percentage < 5) {
                                      titlePositionOffset = 0.8;
                                      fontSize = Scaling.scaleFont(10.0);
                                    } else if (percentage < 10) {
                                      titlePositionOffset = 0.65;
                                      fontSize = Scaling.scaleFont(11.0);
                                    } else {
                                      titlePositionOffset = 0.55;
                                      fontSize = isSelected ? Scaling.scaleFont(14.0) : Scaling.scaleFont(12.0);
                                    }

                                    // Truncate category name, but show the full amount
                                    final truncatedCategory = _truncateString(_getCategoryDisplayName(category), 15);
                                    final amountLabel = '${animatedValue.toStringAsFixed(2)} $currencySymbol';

                                    return PieChartSectionData(
                                      value: animatedValue > 0 ? animatedValue : 0.001,
                                      title: _selectedCategory == category ? "$truncatedCategory\n$amountLabel" : "",
                                      radius: radius,
                                      color: _getChartColor(category),
                                      titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                        fontSize: fontSize,
                                        shadows: isSelected
                                            ? [
                                          Shadow(
                                            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                                            blurRadius: Scaling.scale(4),
                                            offset: const Offset(2, 2),
                                          ),
                                        ]
                                            : null,
                                      ),
                                      showTitle: animatedValue > 0 && _selectedCategory == category,
                                      titlePositionPercentageOffset: titlePositionOffset,
                                    );
                                  }).toList(),
                                ];

                                if (sections.isEmpty || sections.every((s) => s.value == 0 || s.value == 0.001)) {
                                  return _buildNoDataWidget(isDark: isDark);
                                }

                                return Column(
                                  children: [
                                    SizedBox(
                                      height: Scaling.scale(250),
                                      width: double.infinity,
                                      child: PieChart(
                                        PieChartData(
                                          sections: sections,
                                          sectionsSpace: Scaling.scale(2),
                                          centerSpaceRadius: Scaling.scale(40),
                                          pieTouchData: PieTouchData(
                                            enabled: true,
                                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                              if (event is FlTapUpEvent) {
                                                if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                                  if (_selectedCategory != null) {
                                                    _detailsAnimationController.reverse().then((_) {
                                                      setState(() {
                                                        _selectedCategory = null;
                                                        _radiusAnimationController.reverse();
                                                      });
                                                      _pulseAnimationController.forward(from: 0.0);
                                                    });
                                                  }
                                                  return;
                                                }

                                                final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                                if (touchedIndex == -1) return;

                                                final allCategories = [
                                                  ...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"].keys,
                                                  ..._disappearingAnimations.keys,
                                                ];
                                                final newCategory = allCategories.elementAt(touchedIndex);

                                                if (_selectedCategory == newCategory) {
                                                  _detailsAnimationController.reverse().then((_) {
                                                    setState(() {
                                                      _selectedCategory = null;
                                                      _radiusAnimationController.reverse();
                                                    });
                                                  });
                                                } else {
                                                  setState(() {
                                                    _selectedCategory = newCategory;
                                                    _radiusAnimationController.forward(from: 0.0);
                                                    _detailsAnimationController.forward(from: 0.0);
                                                  });
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: Scaling.scalePadding(10)),
                                    _buildLegend({...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"], ..._disappearingValues}, currencySymbol),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(height: Scaling.scalePadding(20)),
                          AnimatedBuilder(
                            animation: _detailsAnimationController,
                            builder: (context, child) {
                              return _selectedCategory != null
                                  ? SlideTransition(
                                position: _detailsSlideAnimation,
                                child: FadeTransition(
                                  opacity: _detailsFadeAnimation,
                                  child: _buildCategoryStats(currencySymbol),
                                ),
                              )
                                  : const SizedBox.shrink();
                            },
                          ),
                          SizedBox(height: Scaling.scalePadding(20)),
                          _buildCategoryFilters(),
                          SizedBox(height: Scaling.scalePadding(20)),
                          _buildChartCard(
                            title: AppLocalizations.of(context)!.monthlySpendingTrends,
                            child: _shouldShowNoDataForMonthlySpending
                                ? _buildNoDataWidget(isDark: isDark)
                                : AnimatedBuilder(
                              animation: _disappearAnimationController,
                              builder: (context, child) {
                                return SizedBox(
                                  height: Scaling.scale(250),
                                  width: double.infinity,
                                  child: BarChart(
                                    BarChartData(
                                      barGroups: (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
                                          .entries
                                          .map<BarChartGroupData>((entry) {
                                        final isSelected = _selectedMonth == entry.key;
                                        return BarChartGroupData(
                                          x: int.parse(entry.key.split('-')[1]),
                                          barRods: [
                                            BarChartRodData(
                                              toY: (entry.value * _disappearAnimation.value).clamp(0.0, double.infinity),
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getBarColor(entry.key),
                                                  _getBarColor(entry.key).withOpacity(0.6),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              width: isSelected ? Scaling.scale(24) : Scaling.scale(16),
                                              borderRadius: BorderRadius.circular(Scaling.scale(4)),
                                              borderSide: isSelected
                                                  ? BorderSide(
                                                color: _getBarColor(entry.key).withOpacity(0.5),
                                                width: Scaling.scale(2),
                                              )
                                                  : const BorderSide(width: 0),
                                              rodStackItems: isSelected
                                                  ? [
                                                BarChartRodStackItem(
                                                  0,
                                                  (entry.value * _disappearAnimation.value).clamp(0.0, double.infinity),
                                                  _getBarColor(entry.key).withOpacity(0.3),
                                                ),
                                              ]
                                                  : [],
                                            ),
                                          ],
                                          showingTooltipIndicators: isSelected ? [0] : [],
                                        );
                                      }).toList(),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                _getMonthLabel(value.toInt()),
                                                style: AppTextStyles.chartLabel(context).copyWith(
                                                  fontSize: Scaling.scaleFont(12),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: Scaling.scale(40),
                                            interval: _calculateYInterval(
                                                (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]),
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                "${value.toInt()}",
                                                style: AppTextStyles.chartLabel(context).copyWith(
                                                  fontSize: Scaling.scaleFont(12),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            strokeWidth: Scaling.scale(1),
                                          );
                                        },
                                      ),
                                      barTouchData: BarTouchData(
                                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                                          if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                            return;
                                          }
                                          setState(() {
                                            final touchedMonth = (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
                                                .keys
                                                .elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                                            _selectedMonth = touchedMonth == _selectedMonth ? null : touchedMonth;
                                          });
                                        },
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipRoundedRadius: Scaling.scale(8),
                                          tooltipMargin: Scaling.scalePadding(8),
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final month = (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
                                                .keys
                                                .elementAt(groupIndex);
                                            return BarTooltipItem(
                                              "${_getMonthLabel(int.parse(month.split('-')[1]))}\n${rod.toY.toStringAsFixed(2)} $currencySymbol",
                                              TextStyle(
                                                color: Colors.white,
                                                fontSize: Scaling.scaleFont(12),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: Scaling.scalePadding(20)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showLoadingOverlay)
            FadeTransition(
              opacity: _loadingFadeAnimation,
              child: Container(
                color: isDark ? AppColors.darkBackground.withOpacity(0.8) : AppColors.lightBackground.withOpacity(0.8),
                child: Center(child: _buildCustomLoadingIndicator()),
              ),
            ),
        ],
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
    double amountValue = double.tryParse(amount) ?? 0.0;
    double fontSize = amountValue >= 1000000
        ? Scaling.scaleFont(16.0)
        : amountValue >= 100000
        ? Scaling.scaleFont(18.0)
        : amountValue >= 10000
        ? Scaling.scaleFont(20.0)
        : amountValue >= 1000
        ? Scaling.scaleFont(22.0)
        : Scaling.scaleFont(24.0);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
      ),
      color: color,
      child: Padding(
        padding: EdgeInsets.all(Scaling.scalePadding(8.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Scaling.scalePadding(8),
                vertical: Scaling.scalePadding(4),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(Scaling.scale(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: Scaling.scale(4),
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: Scaling.scaleIcon(20),
                    color: Colors.white.withOpacity(0.9),
                  ),
                  SizedBox(width: Scaling.scalePadding(6)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Scaling.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Scaling.scalePadding(6)),
            Text(
              '$amount $currencySymbol',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLoadingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: Scaling.scale(50),
      height: Scaling.scale(50),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkAccent, AppColors.darkSecondary]
              : [AppColors.lightAccent, AppColors.lightSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: Scaling.scale(4),
      ),
    );
  }

  Widget _buildDateFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isLeftArrowDisabled = false;
    bool isRightArrowDisabled = false;

    if (_dateFilter != 'Custom' && _selectedStartDate != null && _selectedEndDate != null) {
      if (_dateFilter == 'Daily') {
        final nextDay = _selectedStartDate!.add(const Duration(days: 1));
        isRightArrowDisabled = nextDay.isAfter(today);
      } else if (_dateFilter == 'Weekly') {
        final nextWeekEnd = _selectedEndDate!.add(const Duration(days: 1));
        isRightArrowDisabled = nextWeekEnd.isAfter(today);
      } else if (_dateFilter == 'Monthly') {
        final nextMonthStart = DateTime(_selectedStartDate!.year, _selectedStartDate!.month + 1, 1);
        isRightArrowDisabled = nextMonthStart.isAfter(today);
      } else if (_dateFilter == '3 Months') {
        final nextPeriodEnd = _selectedEndDate!.add(const Duration(days: 1));
        isRightArrowDisabled = nextPeriodEnd.isAfter(today);
      } else if (_dateFilter == '6 Months') {
        final nextPeriodEnd = _selectedEndDate!.add(const Duration(days: 1));
        isRightArrowDisabled = nextPeriodEnd.isAfter(today);
      } else if (_dateFilter == 'Yearly') {
        final nextYearStart = DateTime(_selectedStartDate!.year + 1, 1, 1);
        isRightArrowDisabled = nextYearStart.year > today.year;
      }
    }

    final cardWidth = MediaQuery.of(context).size.width - Scaling.scalePadding(32);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Scaling.scalePadding(16.0)),
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.lightSurface, AppColors.lightBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
            ),
            padding: EdgeInsets.symmetric(
              vertical: Scaling.scalePadding(12.0),
              horizontal: Scaling.scalePadding(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations!.dateRange,
                      style: AppTextStyles.subheading(context),
                    ),
                    if (_areDateFiltersApplied())
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          size: Scaling.scaleIcon(20),
                        ),
                        padding: EdgeInsets.all(Scaling.scalePadding(2.0)),
                        constraints: const BoxConstraints(),
                        onPressed: _clearDateFilter,
                      ),
                  ],
                ),
                SizedBox(height: Scaling.scalePadding(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_dateFilter != 'Custom')
                      IconButton(
                        onPressed: isLeftArrowDisabled ? null : () => _shiftDateRange(-1),
                        icon: Icon(
                          Icons.arrow_left,
                          color: isLeftArrowDisabled
                              ? (isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3))
                              : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                          size: Scaling.scaleIcon(28),
                          weight: 700,
                        ),
                        padding: EdgeInsets.all(Scaling.scalePadding(2.0)),
                        constraints: const BoxConstraints(),
                      ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showCalendarDialog,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: Scaling.scalePadding(8.0),
                            horizontal: Scaling.scalePadding(4.0),
                          ),
                          child: Text(
                            _getDateRangeDisplayText(context),
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: Scaling.scaleFont(16),
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dateFilter != 'Custom')
                          IconButton(
                            onPressed: isRightArrowDisabled ? null : () => _shiftDateRange(1),
                            icon: Icon(
                              Icons.arrow_right,
                              color: isRightArrowDisabled
                                  ? (isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3))
                                  : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                              size: Scaling.scaleIcon(28),
                              weight: 700,
                            ),
                            padding: EdgeInsets.all(Scaling.scalePadding(2.0)),
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            size: Scaling.scaleIcon(20),
                          ),
                          padding: EdgeInsets.all(Scaling.scalePadding(2.0)),
                          constraints: const BoxConstraints(),
                          onPressed: _showCalendarDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations!.categories,
                  style: AppTextStyles.subheading(context),
                ),
                if (_areCategoryFiltersApplied())
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      size: Scaling.scaleIcon(24),
                    ),
                    onPressed: _clearCategoryFilter,
                  ),
              ],
            ),
            SizedBox(height: Scaling.scalePadding(8)),
            Container(
              height: Scaling.scale(200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(Scaling.scale(8)),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                thickness: Scaling.scale(4.0),
                radius: Radius.circular(Scaling.scale(2)),
                child: ListView.builder(
                  itemCount: (_currentPage == 1 ? incomeCategories : expenseCategories).length,
                  itemBuilder: (context, index) {
                    final category = (_currentPage == 1 ? incomeCategories : expenseCategories)[index];
                    final isSelected = selectedCategories.any((c) => c['name'] == category['name']);
                    return CheckboxListTile(
                      title: Text(
                        _getCategoryDisplayName(category['name']),
                        style: AppTextStyles.body(context),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.removeWhere((c) => c['name'] == category['name']);
                          }
                          _fetchData();
                        });
                      },
                      activeColor: _getChartColor(category['name']),
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
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

  Widget _buildChartCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = MediaQuery.of(context).size.width - Scaling.scalePadding(32);

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurface, AppColors.darkBackground]
                  : [AppColors.lightSurface, AppColors.lightBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
          padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.subheading(context),
              ),
              SizedBox(height: Scaling.scalePadding(16)),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget({required bool isDark}) {
    final localizations = AppLocalizations.of(context);
    return Container(
      height: Scaling.scale(100),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: Scaling.scaleIcon(40),
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          SizedBox(height: Scaling.scalePadding(6)),
          Text(
            localizations!.noDataAvailable,
            style: AppTextStyles.body(context).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: Scaling.scaleFont(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> spending, String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: Scaling.scalePadding(8.0),
      runSpacing: Scaling.scalePadding(8.0),
      children: spending.entries.map((entry) {
        final category = entry.key;
        final value = entry.value;

        // Truncate category name to 15 characters
        final truncatedCategory = _truncateString(_getCategoryDisplayName(category), 15);

        // Format the amount and truncate to 7 characters (excluding the decimal part for truncation)
        final amountString = value.toStringAsFixed(2);
        final truncatedAmount = _truncateString(amountString, 7);

        // Combine the truncated amount with the currency symbol
        final amountLabel = truncatedAmount.endsWith('...')
            ? '$truncatedAmount$currencySymbol'
            : '$truncatedAmount $currencySymbol';

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedCategory == category) {
                _selectedCategory = null;
                _radiusAnimationController.reverse();
                _detailsAnimationController.reverse();
              } else {
                _selectedCategory = category;
                _radiusAnimationController.forward(from: 0.0);
                _detailsAnimationController.forward(from: 0.0);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Scaling.scalePadding(10),
              vertical: Scaling.scalePadding(4),
            ),
            decoration: BoxDecoration(
              color: _getChartColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(Scaling.scale(20)),
              border: Border.all(
                color: _getChartColor(category).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Scaling.scale(10),
                  height: Scaling.scale(10),
                  decoration: BoxDecoration(
                    color: _getChartColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: Scaling.scalePadding(6)),
                Text(
                  "$truncatedCategory: $amountLabel",
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: Scaling.scaleFont(12),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryStats(String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final categorySpending = (_isLoading ? _cachedReportsData : _reportsData)["categorySpending"] as Map<String, double>;
    final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
    final value = categorySpending[_selectedCategory] ?? 0.0;
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    // Use the full amount without truncation
    final amountLabel = '${value.toStringAsFixed(2)} $currencySymbol';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        padding: EdgeInsets.all(Scaling.scalePadding(12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_truncateString(_getCategoryDisplayName(_selectedCategory!), 30)} ${localizations!.details}",
              style: AppTextStyles.subheading(context).copyWith(
                fontSize: Scaling.scaleFont(16),
              ),
            ),
            SizedBox(height: Scaling.scalePadding(6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.percentage,
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: Scaling.scaleFont(14),
                  ),
                ),
                Text(
                  "${percentage.toStringAsFixed(1)}%",
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: Scaling.scaleFont(14),
                  ),
                ),
              ],
            ),
            SizedBox(height: Scaling.scalePadding(4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.amount,
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: Scaling.scaleFont(14),
                  ),
                ),
                Text(
                  amountLabel,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: Scaling.scaleFont(14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  }

class _CustomCalendarDialog extends StatefulWidget {
  final _ReportsScreenState parentState;

  const _CustomCalendarDialog({required this.parentState});

  @override
  __CustomCalendarDialogState createState() => __CustomCalendarDialogState();
}

class __CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _calendarDate;

  @override
  void initState() {
    super.initState();
    _calendarDate = widget.parentState._calendarDate;
  }

  void _shiftCalendarMonth(int direction) {
    final now = DateTime.now();
    final nextMonth = DateTime(_calendarDate.year, _calendarDate.month + direction, 1);
    if (direction > 0 && (nextMonth.isAfter(now) && !(nextMonth.month == now.month && nextMonth.year == now.year))) {
      return;
    }
    setState(() {
      _calendarDate = nextMonth;
    });
    widget.parentState._shiftCalendarMonth(direction);
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12.0)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_left,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: Scaling.scaleIcon(24),
                  ),
                  onPressed: () => _shiftCalendarMonth(-1),
                ),
                Text(
                  '${localizations.getMonthName(_calendarDate.month)}, ${_calendarDate.year}',
                  style: AppTextStyles.subheading(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: Scaling.scaleIcon(24),
                  ),
                  onPressed: () => _shiftCalendarMonth(1),
                ),
              ],
            ),
            _buildCalendar(context),
            SizedBox(height: Scaling.scalePadding(16)),
            DropdownButton<String>(
              value: widget.parentState._dateFilter,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'Daily',
                  child: Text(
                    localizations.daily,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Weekly',
                  child: Text(
                    localizations.weekly,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Monthly',
                  child: Text(
                    localizations.monthly,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: '3 Months',
                  child: Text(
                    localizations.last3Months,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: '6 Months',
                  child: Text(
                    localizations.last6Months,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Yearly',
                  child: Text(
                    localizations.yearly,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Custom',
                  child: Text(
                    localizations.custom,
                    style: TextStyle(fontSize: Scaling.scaleFont(14)),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.parentState._updateDateFilter(value);
                  setState(() {});
                }
              },
              style: AppTextStyles.body(context),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              iconSize: Scaling.scaleIcon(24),
              borderRadius: BorderRadius.circular(Scaling.scale(8)),
              menuMaxHeight: Scaling.scale(200),
            ),
            SizedBox(height: Scaling.scalePadding(16)),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Scaling.scale(8)),
                ),
              ),
              child: Text(
                localizations.close,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Scaling.scaleFont(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDayOfMonth = DateTime(_calendarDate.year, _calendarDate.month, 1);
    final lastDayOfMonth = DateTime(_calendarDate.year, _calendarDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday;
    final startingOffset = (firstDayWeekday - 1) % 7;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekdays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Scaling.scaleFont(14),
                ),
              ),
            ),
          )).toList(),
        ),
        SizedBox(height: Scaling.scalePadding(8)),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          childAspectRatio: 1,
          children: List.generate(startingOffset + daysInMonth, (index) {
            if (index < startingOffset) return const SizedBox.shrink();
            final day = index - startingOffset + 1;
            final date = DateTime(_calendarDate.year, _calendarDate.month, day);
            final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
            final isFuture = date.isAfter(today);
            final isSelected = widget.parentState._dateFilter == 'Custom'
                ? (widget.parentState._customStartDate != null &&
                widget.parentState._customEndDate != null &&
                date.isAfter(widget.parentState._customStartDate!.subtract(const Duration(days: 1))) &&
                date.isBefore(widget.parentState._customEndDate!.add(const Duration(days: 1))))
                : (widget.parentState._selectedStartDate != null &&
                date.day == widget.parentState._selectedStartDate!.day &&
                date.month == widget.parentState._selectedStartDate!.month &&
                date.year == widget.parentState._selectedStartDate!.year);

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                widget.parentState._setDateFromCalendarTap(date);
                setState(() {});
              },
              child: Container(
                margin: EdgeInsets.all(Scaling.scalePadding(2)),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkAccent.withOpacity(0.5) : AppColors.lightAccent.withOpacity(0.5))
                      : (isToday
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkAccent.withOpacity(0.3) : AppColors.lightAccent.withOpacity(0.3))
                      : null),
                  borderRadius: BorderRadius.circular(Scaling.scale(8)),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isFuture
                          ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3))
                          : (isSelected || isToday
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          : null),
                      fontWeight: isSelected || isToday ? FontWeight.bold : null,
                      fontSize: Scaling.scaleFont(14),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}
