import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart'; // Import the new styles file

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _reportsFuture;
  List<String> selectedCategories = [];
  List<String> allCategories = [];
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String selectedType = 'expense';
  String? _selectedCategory; // For pie chart
  String? _selectedMonth; // For bar chart

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _reportsFuture = _loadData();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        allCategories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final reports = await _apiService.getReports(
        type: selectedType,
        categories: selectedCategories.isNotEmpty ? selectedCategories : null,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
      );

      final categorySpending = Map<String, double>.from(reports['income_by_category']);
      if (selectedType == 'expense') {
        categorySpending.addAll(Map<String, double>.from(reports['expense_by_category']));
      }

      final transactions = List<Map<String, dynamic>>.from(reports['transactions']);
      final monthlySpending = <String, double>{};
      for (var transaction in transactions) {
        if (transaction['type'] == selectedType) {
          final date = transaction['timestamp'].substring(0, 7);
          final amount = double.parse(transaction['amount'].toString());
          monthlySpending[date] = (monthlySpending[date] ?? 0) + amount;
        }
      }

      return {
        "categorySpending": categorySpending,
        "monthlySpending": monthlySpending,
      };
    } catch (e) {
      throw Exception("Failed to load data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reports & Charts",
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Failed to load data: ${snapshot.error}",
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark ? AppColors.darkError : AppColors.lightError,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No data available",
                  style: AppTextStyles.body(context).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              );
            }

            final categorySpending = snapshot.data!["categorySpending"] as Map<String, double>;
            final monthlySpending = snapshot.data!["monthlySpending"] as Map<String, double>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  const SizedBox(height: 20),
                  _buildChartCard(
                    title: "Category-wise Spending",
                    child: categorySpending.isEmpty
                        ? _buildNoDataWidget()
                        : Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: categorySpending.entries.map((entry) {
                                final isSelected = _selectedCategory == entry.key;
                                return PieChartSectionData(
                                  value: entry.value,
                                  title:
                                  "${entry.key.capitalize()}\n\$${entry.value.toStringAsFixed(2)}",
                                  radius: isSelected ? 70 : 50,
                                  color: _getChartColor(entry.key),
                                  titleStyle: AppTextStyles.chartLabel(context).copyWith(
                                    fontSize: isSelected ? 14 : 12,
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
                                  showTitle: true,
                                  titlePositionPercentageOffset: 0.55,
                                  badgeWidget: isSelected
                                      ? Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getChartColor(entry.key)
                                              .withOpacity(0.5),
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
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    return;
                                  }
                                  setState(() {
                                    final touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                    if (touchedIndex != -1) {
                                      _selectedCategory =
                                          categorySpending.keys.elementAt(touchedIndex);
                                    } else {
                                      _selectedCategory = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLegend(categorySpending),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildChartCard(
                    title: "Monthly Spending Trends",
                    child: monthlySpending.isEmpty
                        ? _buildNoDataWidget()
                        : SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          barGroups: monthlySpending.entries.map((entry) {
                            final isSelected = _selectedMonth == entry.key;
                            return BarChartGroupData(
                              x: int.parse(entry.key.split('-')[1]),
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value,
                                  color: _getBarColor(entry.key),
                                  width: isSelected ? 24 : 16,
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: isSelected
                                      ? BorderSide(
                                    color:
                                    _getBarColor(entry.key).withOpacity(0.5),
                                    width: 2,
                                  )
                                      : const BorderSide(width: 0),
                                  rodStackItems: isSelected
                                      ? [
                                    BarChartRodStackItem(
                                      0,
                                      entry.value,
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
                                interval: _calculateYInterval(monthlySpending),
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    "\$${value.toInt()}",
                                    style: AppTextStyles.chartLabel(context),
                                  );
                                },
                              ),
                            ),
                            topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                final touchedMonth = monthlySpending.keys.elementAt(
                                  barTouchResponse.spot!.touchedBarGroupIndex,
                                );
                                _selectedMonth =
                                touchedMonth == _selectedMonth ? null : touchedMonth;
                              });
                            },
                            touchTooltipData: BarTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final month = monthlySpending.keys.elementAt(groupIndex);
                                return BarTooltipItem(
                                  "${_getMonthLabel(int.parse(month.split('-')[1]))}\n\$${rod.toY.toStringAsFixed(2)}",
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              },
                          ),
                        ),
                      ),
                    ),
                  ),
                  )],
              ),
            );
          },
        ),
      ),
    );
  }

  // Build the filter section
  Widget _buildFilters() {
    return AppCardStyles.card(
      context,
      child: Padding(
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
          ],
        ),
      ),
    );
  }

  // Type filter (expense/income)
  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: selectedType,
      decoration: AppInputStyles.dropdown(context).copyWith(
        labelText: "Type",
      ),
      items: const [
        DropdownMenuItem(value: 'expense', child: Text("Expense")),
        DropdownMenuItem(value: 'income', child: Text("Income")),
      ],
      onChanged: (value) {
        setState(() {
          selectedType = value!;
          selectedCategories.clear();
          _reportsFuture = _loadData();
        });
      },
    );
  }

  // Date range filter
  Widget _buildDateRangeFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  selectedStartDate = date;
                  _reportsFuture = _loadData();
                });
              }
            },
            child: Text(
              selectedStartDate == null
                  ? "Select Start Date"
                  : "Start: ${selectedStartDate!.toLocal().toString().split(' ')[0]}",
              style: AppTextStyles.body(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            style: AppButtonStyles.textButton(context),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  selectedEndDate = date;
                  _reportsFuture = _loadData();
                });
              }
            },
            child: Text(
              selectedEndDate == null
                  ? "Select End Date"
                  : "End: ${selectedEndDate!.toLocal().toString().split(' ')[0]}",
              style: AppTextStyles.body(context),
            ),
          ),
        ),
      ],
    );
  }

  // Category filter
  Widget _buildCategoryFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incomeCategories = ['salary', 'gift', 'interest', 'other_income'];
    final expenseCategories = [
      'food',
      'transport',
      'housing',
      'utilities',
      'entertainment',
      'healthcare',
      'education',
      'shopping',
      'other_expense',
    ];
    final categoriesToShow = selectedType == 'income' ? incomeCategories : expenseCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Filter by Category",
          style: AppTextStyles.subheading(context),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categoriesToShow.map((category) {
            return FilterChip(
              label: Text(category.capitalize()),
              selected: selectedCategories.contains(category),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    selectedCategories.add(category);
                  } else {
                    selectedCategories.remove(category);
                  }
                  _reportsFuture = _loadData();
                });
              },
              selectedColor: _getChartColor(category),
              backgroundColor: isDark
                  ? AppColors.darkTextSecondary.withOpacity(0.2)
                  : AppColors.lightTextSecondary.withOpacity(0.2),
              labelStyle: AppTextStyles.body(context).copyWith(
                color: selectedCategories.contains(category)
                    ? AppColors.lightTextPrimary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: FontWeight.w600,
              ),
              elevation: selectedCategories.contains(category) ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build a card for charts
  Widget _buildChartCard({required String title, required Widget child}) {
    return AppCardStyles.card(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subheading(context),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // Widget to display when no data is available
  Widget _buildNoDataWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        "No data available for the selected filters",
        style: AppTextStyles.body(context).copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  // Build a legend for the pie chart
  Widget _buildLegend(Map<String, double> data) {
    return Wrap(
      spacing: 8,
      children: data.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _getChartColor(entry.key),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key.capitalize(),
              style: AppTextStyles.chartLabel(context),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Get month label for bar chart
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
      'Dec'
    ];
    return months[month - 1];
  }

  // Get a unique color for each category
  Color _getChartColor(String category) {
    return AppColors.categoryColors[category] ??
        AppColors.fallbackColors[category.hashCode % AppColors.fallbackColors.length];
  }

  // Get a unique color for each month in the bar chart
  Color _getBarColor(String month) {
    final monthIndex = int.parse(month.split('-')[1]) - 1;
    return AppColors.fallbackColors[monthIndex % AppColors.fallbackColors.length];
  }

  // Calculate Y-axis interval for bar chart based on max spending
  double _calculateYInterval(Map<String, double> monthlySpending) {
    if (monthlySpending.isEmpty) return 50.0;

    final maxSpending = monthlySpending.values.reduce((a, b) => a > b ? a : b);
    final interval = (maxSpending / 5).ceilToDouble();
    return interval < 10 ? 10 : interval;
  }
}

// Helper function for capitalization
extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}