import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_finance/services/api_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reports & Charts",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load data: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No data available",
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
                              return PieChartSectionData(
                                value: entry.value,
                                title: "${entry.key.capitalize()}\n\$${entry.value.toStringAsFixed(2)}",
                                radius: 50,
                                color: _getChartColor(entry.key),
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                showTitle: true,
                                titlePositionPercentageOffset: 0.55,
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
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
                          return BarChartGroupData(
                            x: int.parse(entry.key.split('-')[1]),
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.blueAccent,
                                    Colors.purpleAccent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _getMonthLabel(value.toInt()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  "\$${value.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
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
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build the filter section
  Widget _buildFilters() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filters",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypeFilter(),
            const SizedBox(height: 12),
            _buildDateRangeFilter(),
            const SizedBox(height: 12),
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
      decoration: InputDecoration(
        labelText: "Type",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'expense', child: Text("Expense")),
        DropdownMenuItem(value: 'income', child: Text("Income")),
      ],
      onChanged: (value) {
        setState(() {
          selectedType = value!;
          selectedCategories.clear(); // Reset categories when type changes
          _reportsFuture = _loadData();
        });
      },
    );
  }

  // Date range filter
  Widget _buildDateRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
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
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
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
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // Category filter
  Widget _buildCategoryFilter() {
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
        const Text(
          "Filter by Category",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: selectedCategories.contains(category)
                    ? Colors.white
                    : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build a card for charts
  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  // Widget to display when no data is available
  Widget _buildNoDataWidget() {
    return const Center(
      child: Text(
        "No data available for the selected filters",
        style: TextStyle(color: Colors.grey, fontSize: 16),
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
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Get month label for bar chart
  String _getMonthLabel(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Get a unique color for each category
  Color _getChartColor(String category) {
    final colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.redAccent,
    ];
    return colors[category.hashCode % colors.length];
  }
}

// Helper function for capitalization
extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}