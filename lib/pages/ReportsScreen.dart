import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/providers/theme_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
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
  List<String> selectedCategories = [];
  List<String> allCategories = [];
  List<String> expenseCategories = [];
  List<String> incomeCategories = [];
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int _currentPage = 0; // 0: Expense, 1: Income
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

  @override
  void initState() {
    super.initState();
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
    _selectRadiusAnimation = Tween<double>(begin: 50.0, end: 70.0).animate(
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
      TweenSequenceItem(tween: Tween<double>(begin: 50.0, end: 60.0), weight: 50.0),
      TweenSequenceItem(tween: Tween<double>(begin: 60.0, end: 50.0), weight: 50.0),
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

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        allCategories = categories;
        expenseCategories = categories
            .where((category) => !['salary', 'gift', 'interest', 'other_income'].contains(category))
            .toList();
        incomeCategories = categories
            .where((category) => ['salary', 'gift', 'interest', 'other_income'].contains(category))
            .toList();
      });
    } catch (e) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.failedToLoadCategories(e.toString()),
        isError: true,
      );
    }
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
      final String selectedType = _currentPage == 0 ? 'expense' : 'income';
      final reports = await _apiService.getReports(
        type: selectedType,
        categories: selectedCategories.isNotEmpty ? selectedCategories : null,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
      );

      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final currentCurrency = currencyProvider.currency;

      final Map<String, double> categorySpending = {};
      if (selectedType == 'income') {
        final incomeSpending = Map<String, dynamic>.from(reports['income_by_category'] ?? {});
        incomeSpending.forEach((key, value) {
          if (key != null && value != null) {
            final amountInKGS = (value is double) ? value : double.parse(value.toString());
            final convertedAmount = _convertAmount(amountInKGS, null, null, currentCurrency);
            categorySpending[key] = convertedAmount;
          }
        });
      } else {
        final expenseSpending = Map<String, dynamic>.from(reports['expense_by_category'] ?? {});
        expenseSpending.forEach((key, value) {
          if (key != null && value != null) {
            final amountInKGS = (value is double) ? value : double.parse(value.toString());
            final convertedAmount = _convertAmount(amountInKGS, null, null, currentCurrency);
            categorySpending[key] = convertedAmount;
          }
        });
      }

      final Map<String, double> monthlySpending = {};
      final transactions = List<Map<String, dynamic>>.from(reports['transactions'] ?? []);
      for (var transaction in transactions) {
        if (transaction['type'] == selectedType) {
          final date = transaction['timestamp'].substring(0, 7);
          final amountInKGS = double.parse(transaction['amount'].toString());
          final originalAmount = transaction['original_amount'] != null
              ? double.parse(transaction['original_amount'].toString())
              : null;
          final originalCurrency = transaction['original_currency'] as String?;
          final convertedAmount = _convertAmount(amountInKGS, originalAmount, originalCurrency, currentCurrency);
          monthlySpending[date] = (monthlySpending[date] ?? 0) + convertedAmount;
        }
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
        message: AppLocalizations.of(context)!.failedToLoadData(e.toString()),
        isError: true,
      );
    }
  }

  double _convertAmount(double amountInKGS, double? originalAmount, String? originalCurrency, String targetCurrency) {
    if (originalAmount != null && originalCurrency != null && originalCurrency == targetCurrency) {
      return originalAmount;
    }
    try {
      final rate = _currencyApiService.getConversionRate('KGS', targetCurrency);
      return amountInKGS * rate;
    } catch (e) {
      print('Error converting amount: $e');
      return amountInKGS;
    }
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

  bool _areFiltersApplied() {
    return selectedStartDate != null || selectedEndDate != null || selectedCategories.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      selectedStartDate = null;
      selectedEndDate = null;
      selectedCategories.clear();
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

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
                // Header like History Screen
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 24),
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
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
                  thickness: 1,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.reportsAndInsights,
                      style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards moved inside SingleChildScrollView
                          SizedBox(
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: MediaQuery.of(context).size.width - 32,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: 2, // Limit to 2 pages: Expense and Income
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index; // 0 for Expense, 1 for Income
                                      });
                                      _fetchData();
                                    },
                                    itemBuilder: (context, index) {
                                      final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
                                      return _buildSummaryCard(
                                        title: index == 0
                                            ? AppLocalizations.of(context)!.expenses
                                            : AppLocalizations.of(context)!.income,
                                        amount: total.toStringAsFixed(2),
                                        currencySymbol: currencySymbol,
                                        color: index == 0 ? const Color(0xFF990033) : const Color(0xFF009966),
                                        icon: index == 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                      );
                                    },
                                  ),
                                ),
                                if (_currentPage != 0) // Show left arrow only if not on Expense
                                  Positioned(
                                    left: 0,
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
                                if (_currentPage != 1) // Show right arrow only if not on Income
                                  Positioned(
                                    right: 0,
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
                          const SizedBox(height: 20),
                          _buildFilters(),
                          const SizedBox(height: 20),
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
                                final total =
                                (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: 250,
                                      width: double.infinity,
                                      child: PieChart(
                                        PieChartData(
                                          sections: [
                                            ...(_isLoading ? _cachedReportsData : _reportsData)[
                                            "categorySpending"]
                                                .entries
                                                .map<PieChartSectionData>((entry) {
                                              final category = entry.key;
                                              final isSelected = _selectedCategory == category;
                                              final baseRadius =
                                              (50.0 * _disappearAnimation.value).clamp(0.0, 50.0);
                                              final selectionRadius =
                                              isSelected ? _selectRadiusAnimation.value : baseRadius;
                                              final radius = isSelected
                                                  ? selectionRadius + (_pulseAnimation.value - 50.0)
                                                  : baseRadius;
                                              final animatedValue =
                                                  _valueAnimations[category]?.value ?? 0.0;

                                              final percentage = total > 0 ? (animatedValue / total) * 100 : 0.0;

                                              double titlePositionOffset;
                                              double fontSize;
                                              if (percentage < 5) {
                                                titlePositionOffset = 0.8;
                                                fontSize = 10.0;
                                              } else if (percentage < 10) {
                                                titlePositionOffset = 0.65;
                                                fontSize = 11.0;
                                              } else {
                                                titlePositionOffset = 0.55;
                                                fontSize = isSelected ? 14.0 : 12.0;
                                              }

                                              return PieChartSectionData(
                                                value: animatedValue > 0 ? animatedValue : 0.001,
                                                title: _selectedCategory == category
                                                    ? "${AppLocalizations.of(context)!.getCategoryName(category)}\n${animatedValue.toStringAsFixed(2)} $currencySymbol"
                                                    : "",
                                                radius: radius,
                                                color: _getChartColor(category),
                                                titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                                  fontSize: fontSize,
                                                  shadows: isSelected
                                                      ? [
                                                    Shadow(
                                                      color: isDark
                                                          ? AppColors.darkShadow
                                                          : AppColors.lightShadow,
                                                      blurRadius: 4,
                                                      offset: const Offset(2, 2),
                                                    ),
                                                  ]
                                                      : null,
                                                ),
                                                showTitle: animatedValue > 0 && _selectedCategory == category,
                                                titlePositionPercentageOffset: titlePositionOffset,
                                              );
                                            }).toList(),
                                            ..._disappearingAnimations.entries
                                                .map<PieChartSectionData>((entry) {
                                              final category = entry.key;
                                              final isSelected = _selectedCategory == category;
                                              final baseRadius =
                                              (50.0 * _disappearAnimation.value).clamp(0.0, 50.0);
                                              final selectionRadius =
                                              isSelected ? _selectRadiusAnimation.value : baseRadius;
                                              final radius = isSelected
                                                  ? selectionRadius + (_pulseAnimation.value - 50.0)
                                                  : baseRadius;
                                              final animatedValue = entry.value.value;

                                              final percentage = total > 0 ? (animatedValue / total) * 100 : 0.0;

                                              double titlePositionOffset;
                                              double fontSize;
                                              if (percentage < 5) {
                                                titlePositionOffset = 0.8;
                                                fontSize = 10.0;
                                              } else if (percentage < 10) {
                                                titlePositionOffset = 0.65;
                                                fontSize = 11.0;
                                              } else {
                                                titlePositionOffset = 0.55;
                                                fontSize = isSelected ? 14.0 : 12.0;
                                              }

                                              return PieChartSectionData(
                                                value: animatedValue > 0 ? animatedValue : 0.001,
                                                title: _selectedCategory == category
                                                    ? "${AppLocalizations.of(context)!.getCategoryName(category)}\n${animatedValue.toStringAsFixed(2)} $currencySymbol"
                                                    : "",
                                                radius: radius,
                                                color: _getChartColor(category),
                                                titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                                  fontSize: fontSize,
                                                  shadows: isSelected
                                                      ? [
                                                    Shadow(
                                                      color: isDark
                                                          ? AppColors.darkShadow
                                                          : AppColors.lightShadow,
                                                      blurRadius: 4,
                                                      offset: const Offset(2, 2),
                                                    ),
                                                  ]
                                                      : null,
                                                ),
                                                showTitle: animatedValue > 0 && _selectedCategory == category,
                                                titlePositionPercentageOffset: titlePositionOffset,
                                              );
                                            }).toList(),
                                          ],
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 40,
                                          pieTouchData: PieTouchData(
                                            enabled: true,
                                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                              if (event is FlTapUpEvent) {
                                                if (pieTouchResponse == null ||
                                                    pieTouchResponse.touchedSection == null) {
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

                                                final touchedIndex =
                                                    pieTouchResponse.touchedSection!.touchedSectionIndex;
                                                if (touchedIndex == -1) return;

                                                final allCategories = [
                                                  ...(_isLoading ? _cachedReportsData : _reportsData)[
                                                  "categorySpending"]
                                                      .keys,
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
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    _scrollController.animateTo(
                                                      _scrollController.position.maxScrollExtent,
                                                      duration: const Duration(milliseconds: 300),
                                                      curve: Curves.easeInOut,
                                                    );
                                                  });
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildLegend({
                                      ...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"],
                                      ..._disappearingValues,
                                    }, currencySymbol),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
                          _buildChartCard(
                            title: AppLocalizations.of(context)!.monthlySpendingTrends,
                            child: _shouldShowNoDataForMonthlySpending
                                ? _buildNoDataWidget(isDark: isDark)
                                : AnimatedBuilder(
                              animation: _disappearAnimationController,
                              builder: (context, child) {
                                return SizedBox(
                                  height: 250,
                                  width: double.infinity,
                                  child: BarChart(
                                    BarChartData(
                                      barGroups: (_isLoading ? _cachedReportsData : _reportsData)[
                                      "monthlySpending"]
                                          .entries
                                          .map<BarChartGroupData>((entry) {
                                        final isSelected = _selectedMonth == entry.key;
                                        return BarChartGroupData(
                                          x: int.parse(entry.key.split('-')[1]),
                                          barRods: [
                                            BarChartRodData(
                                              toY: (entry.value * _disappearAnimation.value)
                                                  .clamp(0.0, double.infinity),
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getBarColor(entry.key),
                                                  _getBarColor(entry.key).withOpacity(0.6),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              width: isSelected ? 24 : 16,
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: isSelected
                                                  ? BorderSide(
                                                color: _getBarColor(entry.key).withOpacity(0.5),
                                                width: 2,
                                              )
                                                  : const BorderSide(width: 0),
                                              rodStackItems: isSelected
                                                  ? [
                                                BarChartRodStackItem(
                                                  0,
                                                  (entry.value * _disappearAnimation.value)
                                                      .clamp(0.0, double.infinity),
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
                                                style: AppTextStyles.chartLabel(context),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            interval: _calculateYInterval(
                                                (_isLoading ? _cachedReportsData : _reportsData)[
                                                "monthlySpending"]),
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                "${value.toInt()}",
                                                style: AppTextStyles.chartLabel(context),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles:
                                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      barTouchData: BarTouchData(
                                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                                          if (!event.isInterestedForInteractions ||
                                              barTouchResponse == null ||
                                              barTouchResponse.spot == null) {
                                            return;
                                          }
                                          setState(() {
                                            final touchedMonth = (_isLoading
                                                ? _cachedReportsData
                                                : _reportsData)["monthlySpending"]
                                                .keys
                                                .elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                                            _selectedMonth = touchedMonth == _selectedMonth ? null : touchedMonth;
                                          });
                                        },
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipRoundedRadius: 8,
                                          tooltipMargin: 8,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final month = (_isLoading ? _cachedReportsData : _reportsData)[
                                            "monthlySpending"]
                                                .keys
                                                .elementAt(groupIndex);
                                            return BarTooltipItem(
                                              "${_getMonthLabel(int.parse(month.split('-')[1]))}\n${rod.toY.toStringAsFixed(2)} $currencySymbol",
                                              const TextStyle(color: Colors.white, fontSize: 12),
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
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Text(
                                "Scroll to Bottom", // Placeholder until AppLocalizations is updated
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
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

// Updated _buildSummaryCard with glass label effect
  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required String currencySymbol,
    required Color color,
    required IconData icon,
  }) {
    double amountValue = double.tryParse(amount) ?? 0.0;
    double fontSize = amountValue >= 1000000
        ? 20.0
        : amountValue >= 100000
        ? 22.0
        : amountValue >= 10000
        ? 24.0
        : amountValue >= 1000
        ? 26.0
        : 28.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glass label effect
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
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
                    size: 24,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
    );
  }

  Widget _buildCustomLoadingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 50,
      height: 50,
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
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 4,
      ),
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.filters, style: AppTextStyles.subheading(context)),
            const SizedBox(height: 12),
            _buildDateRangeFilter(),
            const SizedBox(height: 16),
            _buildCategoryFilter(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _areFiltersApplied() ? _clearFilters : null,
                style: AppButtonStyles.outlinedButton(context).copyWith(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: _areFiltersApplied()
                          ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.refresh,
                  color: _areFiltersApplied()
                      ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                ),
                label: Text(
                  AppLocalizations.of(context)!.clearFilters,
                  style: AppTextStyles.body(context).copyWith(
                    color: _areFiltersApplied()
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => selectedStartDate = picked);
                _fetchData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedStartDate == null
                    ? AppLocalizations.of(context)!.startDate
                    : "${selectedStartDate!.toLocal()}".split(' ')[0],
                style: AppTextStyles.body(context).copyWith(
                  color: selectedStartDate == null
                      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => selectedEndDate = picked);
                _fetchData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedEndDate == null
                    ? AppLocalizations.of(context)!.endDate
                    : "${selectedEndDate!.toLocal()}".split(' ')[0],
                style: AppTextStyles.body(context).copyWith(
                  color: selectedEndDate == null
                      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categoriesToShow = _currentPage == 1 ? incomeCategories : expenseCategories;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: categoriesToShow.map((category) {
        final isSelected = selectedCategories.contains(category);
        final categoryColor = _getChartColor(category);
        return FilterChip(
          label: Text(
            AppLocalizations.of(context)!.getCategoryName(category),
            style: AppTextStyles.body(context).copyWith(
              color: isSelected
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
            ),
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedCategories.add(category);
              } else {
                selectedCategories.remove(category);
              }
            });
            _fetchData();
          },
          selectedColor: categoryColor,
          backgroundColor: categoryColor.withOpacity(0.2),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: categoryColor.withOpacity(0.5)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.subheading(context)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget({required bool isDark}) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 50,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.noDataAvailable,
            style: AppTextStyles.body(context).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> spending, String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: spending.entries.map((entry) {
        final category = entry.key;
        final value = entry.value;
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getChartColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getChartColor(category).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getChartColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${AppLocalizations.of(context)!.getCategoryName(category)}: ${value.toStringAsFixed(2)} $currencySymbol",
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
    final categorySpending = (_isLoading ? _cachedReportsData : _reportsData)["categorySpending"] as Map<String, double>;
    final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
    final value = categorySpending[_selectedCategory] ?? 0.0;
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context)!.getCategoryName(_selectedCategory!)} ${AppLocalizations.of(context)!.details}",
              style: AppTextStyles.subheading(context),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.amount,
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  "${value.toStringAsFixed(2)} $currencySymbol",
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.percentage,
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  "${percentage.toStringAsFixed(1)}%",
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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