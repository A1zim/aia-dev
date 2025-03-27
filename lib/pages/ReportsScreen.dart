import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/notification_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/services/currency_api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
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
  String selectedType = 'expense';
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
      TweenSequenceItem(
        tween: Tween<double>(begin: 50.0, end: 60.0),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 60.0, end: 50.0),
        weight: 50.0,
      ),
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
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: -0.1),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0.0),
        weight: 30.0,
      ),
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
        message: 'Failed to load categories: $e',
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
        final incomeSpending = Map<String, dynamic>.from(reports['income_by_category']);
        incomeSpending.forEach((key, value) {
          if (key != null && value != null) {
            final amountInKGS = (value is double) ? value : double.parse(value.toString());
            final convertedAmount = _convertAmount(amountInKGS, null, null, currentCurrency);
            categorySpending[key] = convertedAmount;
          }
        });
      } else {
        final expenseSpending = Map<String, dynamic>.from(reports['expense_by_category']);
        expenseSpending.forEach((key, value) {
          if (key != null && value != null) {
            final amountInKGS = (value is double) ? value : double.parse(value.toString());
            final convertedAmount = _convertAmount(amountInKGS, null, null, currentCurrency);
            categorySpending[key] = convertedAmount;
          }
        });
      }

      final Map<String, double> monthlySpending = {};
      final transactions = List<Map<String, dynamic>>.from(reports['transactions']);
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

      final bool newCategorySpendingEmpty = (newReportsData["categorySpending"] as Map<String, double>)!.isEmpty;
      final bool newMonthlySpendingEmpty = (newReportsData["monthlySpending"] as Map<String, double>)!.isEmpty;

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
        message: 'Failed to load data: $e',
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
      return amountInKGS; // Fallback to KGS if conversion fails
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reports & Insights",
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
        elevation: 8,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
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
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(currencySymbol),
                    const SizedBox(height: 20),
                    _buildFilters(),
                    const SizedBox(height: 20),
                    _buildChartCard(
                      title: "Category-wise Spending",
                      child: _shouldShowNoDataForCategorySpending
                          ? _buildNoDataWidget()
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

                          return Column(
                            children: [
                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: AbsorbPointer(
                                  absorbing: false,
                                  child: GestureDetector(
                                    onTapDown: (details) {
                                      print("GestureDetector onTapDown triggered");
                                    },
                                    onTapUp: (details) {
                                      print("GestureDetector onTapUp triggered");
                                    },
                                    onPanDown: (details) {
                                      print("GestureDetector onPanDown triggered");
                                    },
                                    child: PieChart(
                                      PieChartData(
                                        sections: [
                                          ...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"]
                                              .entries
                                              .map<PieChartSectionData>((entry) {
                                            final category = entry.key;
                                            final isSelected = _selectedCategory == category;
                                            final baseRadius = (50.0 * _disappearAnimation.value).clamp(0.0, 50.0);
                                            final selectionRadius = isSelected ? _selectRadiusAnimation.value : baseRadius;
                                            final radius = isSelected ? selectionRadius + (_pulseAnimation.value - 50.0) : baseRadius;
                                            final animatedValue = _valueAnimations[category]?.value ?? 0.0;

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

                                            print(
                                                "Rendering pie chart section for category: $category, animatedValue: $animatedValue, radius: $radius, percentage: $percentage");

                                            return PieChartSectionData(
                                              value: animatedValue > 0 ? animatedValue : 0.001,
                                              title: _selectedCategory == category
                                                  ? "${category.isEmpty ? 'Unknown' : '${category[0].toUpperCase()}${category.substring(1).replaceAll('_', ' ')}'}\n${animatedValue.toStringAsFixed(2)} $currencySymbol"
                                                  : "",
                                              radius: radius,
                                              color: _getChartColor(category),
                                              titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                                fontSize: fontSize,
                                                shadows: isSelected
                                                    ? [
                                                  Shadow(
                                                    color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                                                    blurRadius: 4,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ]
                                                    : null,
                                              ),
                                              showTitle: animatedValue > 0 && _selectedCategory == category,
                                              titlePositionPercentageOffset: titlePositionOffset,
                                              badgeWidget: isSelected
                                                  ? Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _getChartColor(category).withOpacity(0.5),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  color: Colors.yellow,
                                                  size: 16,
                                                ),
                                              )
                                                  : null,
                                            );
                                          }).toList(),
                                          ..._disappearingAnimations.entries.map<PieChartSectionData>((entry) {
                                            final category = entry.key;
                                            final isSelected = _selectedCategory == category;
                                            final baseRadius = (50.0 * _disappearAnimation.value).clamp(0.0, 50.0);
                                            final selectionRadius = isSelected ? _selectRadiusAnimation.value : baseRadius;
                                            final radius = isSelected ? selectionRadius + (_pulseAnimation.value - 50.0) : baseRadius;
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

                                            print(
                                                "Rendering disappearing pie chart section for category: $category, animatedValue: $animatedValue, radius: $radius, percentage: $percentage");

                                            return PieChartSectionData(
                                              value: animatedValue > 0 ? animatedValue : 0.001,
                                              title: _selectedCategory == category
                                                  ? "${category.isEmpty ? 'Unknown' : '${category[0].toUpperCase()}${category.substring(1).replaceAll('_', ' ')}'}\n${animatedValue.toStringAsFixed(2)} $currencySymbol"
                                                  : "",
                                              radius: radius,
                                              color: _getChartColor(category),
                                              titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                                fontSize: fontSize,
                                                shadows: isSelected
                                                    ? [
                                                  Shadow(
                                                    color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                                                    blurRadius: 4,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ]
                                                    : null,
                                              ),
                                              showTitle: animatedValue > 0 && _selectedCategory == category,
                                              titlePositionPercentageOffset: titlePositionOffset,
                                              badgeWidget: isSelected
                                                  ? Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _getChartColor(category).withOpacity(0.5),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  color: Colors.yellow,
                                                  size: 16,
                                                ),
                                              )
                                                  : null,
                                            );
                                          }).toList(),
                                        ],
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        pieTouchData: PieTouchData(
                                          enabled: true,
                                          longPressDuration: const Duration(seconds: 1000),
                                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                            print("Event type: ${event.runtimeType}, isInterestedForInteractions: ${event.isInterestedForInteractions}");
                                            print("PieTouchResponse: $pieTouchResponse");

                                            if (event is FlTapUpEvent) {
                                              if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                                print("Field tapped, deselecting category and triggering pulse");
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
                                              if (touchedIndex == -1) {
                                                print("Invalid section index, ignoring");
                                                return;
                                              }

                                              final allCategories = [
                                                ...(_isLoading ? _cachedReportsData : _reportsData)["categorySpending"].keys,
                                                ..._disappearingAnimations.keys,
                                              ];
                                              final newCategory = allCategories.elementAt(touchedIndex);
                                              print("Section tapped, category: $newCategory, current selected: $_selectedCategory");

                                              if (_selectedCategory == newCategory) {
                                                print("Same section tapped, deselecting");
                                                _detailsAnimationController.reverse().then((_) {
                                                  setState(() {
                                                    _selectedCategory = null;
                                                    _radiusAnimationController.reverse();
                                                  });
                                                });
                                              } else {
                                                print("New section tapped, selecting");
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
                        print("AnimatedBuilder rebuilding, _selectedCategory: $_selectedCategory");
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
                      title: "Monthly Spending Trends",
                      child: _shouldShowNoDataForMonthlySpending
                          ? _buildNoDataWidget()
                          : AnimatedBuilder(
                        animation: _disappearAnimationController,
                        builder: (context, child) {
                          return SizedBox(
                            height: 250,
                            width: double.infinity,
                            child: BarChart(
                              BarChartData(
                                barGroups: (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
                                    .entries
                                    .map<BarChartGroupData>((entry) {
                                  final isSelected = _selectedMonth == entry.key;
                                  print("Rendering bar chart group for month: ${entry.key}, value: ${entry.value}");
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
                                          (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]),
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          "${value.toInt()}",
                                          style: AppTextStyles.chartLabel(context),
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
                                      final touchedMonth = (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
                                          .keys
                                          .elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                                      _selectedMonth = touchedMonth == _selectedMonth ? null : touchedMonth;
                                    });
                                  },
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipRoundedRadius: 8,
                                    tooltipMargin: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final month = (_isLoading ? _cachedReportsData : _reportsData)["monthlySpending"]
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
                  ],
                ),
              ),
            ),
          ),
          if (_showLoadingOverlay)
            FadeTransition(
              opacity: _loadingFadeAnimation,
              child: Container(
                color: isDark ? AppColors.darkBackground.withOpacity(0.8) : AppColors.lightBackground.withOpacity(0.8),
                child: Center(
                  child: _buildCustomLoadingIndicator(),
                ),
              ),
            ),
        ],
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

  Widget _buildSummaryCard(String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = (_isLoading ? _cachedReportsData : _reportsData)["total"] as double;
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total ${selectedType.isEmpty ? 'Unknown' : '${selectedType[0].toUpperCase()}${selectedType.substring(1).replaceAll('_', ' ')}'}",
                  style: AppTextStyles.subheading(context),
                ),
                const SizedBox(height: 8),
                Text(
                  "${total.toStringAsFixed(2)} $currencySymbol",
                  style: AppTextStyles.heading(context).copyWith(
                    color: selectedType == 'income' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            Icon(
              selectedType == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              color: selectedType == 'income' ? Colors.green : Colors.red,
              size: 40,
            ),
          ],
        ),
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
            Text(
              "Filters",
              style: AppTextStyles.subheading(context),
            ),
            const SizedBox(height: 12),
            _buildTypeFilter(),
            const SizedBox(height: 16),
            _buildDateRangeFilter(),
            const SizedBox(height: 16),
            _buildCategoryFilter(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _areFiltersApplied() ? _clearFilters : null,
                style: AppButtonStyles.outlinedButton(context).copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
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
                  "Clear Filters",
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

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: selectedType,
      decoration: AppInputStyles.dropdown(context).copyWith(
        labelText: "Type",
        prefixIcon: Icon(
          Icons.filter_list,
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkAccent : AppColors.lightAccent,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'expense', child: Text("Expense")),
        DropdownMenuItem(value: 'income', child: Text("Income")),
      ],
      onChanged: (value) {
        setState(() {
          selectedType = value!;
          selectedCategories.clear();
        });
        _fetchData();
      },
      style: AppTextStyles.body(context),
      dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
      icon: AppInputStyles.dropdownProperties(context)['icon'],
      menuMaxHeight: AppInputStyles.dropdownProperties(context)['menuMaxHeight'],
      borderRadius: AppInputStyles.dropdownProperties(context)['borderRadius'],
      elevation: AppInputStyles.dropdownProperties(context)['elevation'],
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
                setState(() {
                  selectedStartDate = picked;
                });
                _fetchData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedStartDate == null
                    ? "Start Date"
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
                setState(() {
                  selectedEndDate = picked;
                });
                _fetchData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedEndDate == null
                    ? "End Date"
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
    final categoriesToShow = selectedType == 'income' ? incomeCategories : expenseCategories;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: categoriesToShow.map((category) {
        final isSelected = selectedCategories.contains(category);
        final categoryColor = _getChartColor(category);
        return FilterChip(
          label: Text(
            category.isEmpty ? 'Unknown' : '${category[0].toUpperCase()}${category.substring(1).replaceAll('_', ' ')}',
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
            side: BorderSide(
              color: categoryColor.withOpacity(0.5),
            ),
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
            Text(
              title,
              style: AppTextStyles.subheading(context),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            "No data available",
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
              border: Border.all(
                color: _getChartColor(category).withOpacity(0.5),
              ),
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
                  "${category.isEmpty ? 'Unknown' : '${category[0].toUpperCase()}${category.substring(1).replaceAll('_', ' ')}'}: ${value.toStringAsFixed(2)} $currencySymbol",
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
              "${_selectedCategory!.isEmpty ? 'Unknown' : '${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1).replaceAll('_', ' ')}'} Details",
              style: AppTextStyles.subheading(context),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount",
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
                  "Percentage",
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