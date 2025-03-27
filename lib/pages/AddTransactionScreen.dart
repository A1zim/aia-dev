import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/services/notification_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'dart:io'; // For SocketException
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _displayCurrency = 'KGS'; // Currency for the amount displayed in the TextFormField

  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();

  List<String> _expenseCategories = [
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

  List<String> _incomeCategories = [
    'salary',
    'gift',
    'interest',
    'other_income',
  ];

  @override
  void initState() {
    super.initState();
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

    if (widget.transaction != null) {
      // Edit mode: Populate fields with transaction data
      _descriptionController.text = widget.transaction!.description;
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = DateTime.parse(widget.transaction!.timestamp);

      // Determine the amount to display in the TextFormField
      if (widget.transaction!.originalAmount != null && widget.transaction!.originalCurrency != null) {
        // Use originalAmount and originalCurrency if available
        _amountController.text = widget.transaction!.originalAmount!.toStringAsFixed(2);
        _displayCurrency = widget.transaction!.originalCurrency!;
      } else {
        // Fallback to amount in KGS and convert to current currency
        double amountInCurrentCurrency = widget.transaction!.amount;
        if (currencyProvider.currency != 'KGS') {
          try {
            double conversionRate = _currencyApiService.getConversionRate('KGS', currencyProvider.currency);
            amountInCurrentCurrency = widget.transaction!.amount * conversionRate;
          } catch (e) {
            print('Error converting amount for edit: $e');
            // Fallback to KGS if conversion fails
            _displayCurrency = 'KGS';
          }
        }
        _amountController.text = amountInCurrentCurrency.toStringAsFixed(2);
        _displayCurrency = currencyProvider.currency;
      }
    } else {
      // Add mode: Set _displayCurrency to the app's selected currency
      _displayCurrency = currencyProvider.currency;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Define transactionCurrency at a higher scope
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final String transactionCurrency = widget.transaction != null ? _displayCurrency : currencyProvider.currency;

      try {
        final double enteredAmount = double.parse(_amountController.text);

        // Convert the entered amount to KGS using CurrencyApiService
        double amountInKGS;
        double conversionRate;
        if (transactionCurrency == 'KGS') {
          amountInKGS = enteredAmount;
          conversionRate = 1.0;
        } else {
          // Fetch the conversion rate for the transaction's currency to KGS
          conversionRate = _currencyApiService.getConversionRate(transactionCurrency, 'KGS');
          amountInKGS = enteredAmount * conversionRate;

          // Verify that the conversion rate matches CurrencyProvider
          if (transactionCurrency == currencyProvider.currency && conversionRate != currencyProvider.exchangeRate) {
            print('Warning: CurrencyProvider exchange rate (${currencyProvider.exchangeRate}) does not match CurrencyApiService rate ($conversionRate) for $transactionCurrency');
          }
        }

        // Log the values for debugging
        print('Entered Amount: $enteredAmount $transactionCurrency');
        print('Conversion Rate ($transactionCurrency to KGS): $conversionRate');
        print('Converted Amount in KGS: $amountInKGS KGS');

        final transaction = Transaction(
          id: widget.transaction?.id ?? 0,
          user: widget.transaction?.user ?? 0,
          type: _selectedType,
          category: _selectedCategory,
          amount: amountInKGS,
          description: _descriptionController.text,
          timestamp: _selectedDate.toIso8601String(),
          username: widget.transaction?.username ?? '',
          originalCurrency: transactionCurrency,
          originalAmount: enteredAmount,
        );

        // Log the transaction object
        print('Transaction to Save: ${transaction.toString()}');

        if (widget.transaction == null) {
          await _apiService.addTransaction(transaction);
        } else {
          await _apiService.updateTransaction(widget.transaction!.id, transaction);
        }

        if (mounted) {
          NotificationService.showNotification(
            context,
            message: widget.transaction == null
                ? 'Transaction added successfully'
                : 'Transaction updated successfully',
          );

          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          if (e is SocketException) {
            errorMessage = 'Network error. Please check your connection.';
          } else if (e.toString().contains('Unsupported currency')) {
            final currencySymbol = _currencyApiService.getCurrencySymbol(transactionCurrency);
            errorMessage = 'The selected currency ($currencySymbol) is not supported.';
          }

          NotificationService.showNotification(
            context,
            message: errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Add a method to get a color for each category based on its name
  Color _getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'food': const Color(0xFFEF5350), // Red for food
      'transport': const Color(0xFF42A5F5), // Blue for transport
      'housing': const Color(0xFFAB47BC), // Purple for housing
      'utilities': const Color(0xFF26C6DA), // Cyan for utilities
      'entertainment': const Color(0xFFFFCA28), // Yellow for entertainment
      'healthcare': const Color(0xFF4CAF50), // Green for healthcare
      'education': const Color(0xFFFF8A65), // Orange for education
      'shopping': const Color(0xFFD4E157), // Lime for shopping
      'other_expense': const Color(0xFF90A4AE), // Grey for other_expense
      'salary': const Color(0xFF66BB6A), // Light Green for salary
      'gift': const Color(0xFFF06292), // Pink for gift
      'interest': const Color(0xFF29B6F6), // Light Blue for interest
      'other_income': const Color(0xFF78909C), // Blue Grey for other_income
    };
    return categoryColors[category] ?? Colors.grey.withOpacity(0.8);
  }

  // Add a method to get a color for each transaction type
  Color _getTypeColor(String type) {
    final Map<String, Color> typeColors = {
      'expense': const Color(0xFFEF5350), // Red for expense
      'income': const Color(0xFF4CAF50), // Green for income
    };
    return typeColors[type] ?? Colors.grey.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    List<String> _categories =
    _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final displayCurrencySymbol = _currencyApiService.getCurrencySymbol(_displayCurrency);
    final kgsSymbol = _currencyApiService.getCurrencySymbol('KGS');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Type Toggle Buttons (Expense <-> Income)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.transaction != null
                                  ? null // Disable in edit mode
                                  : () {
                                setState(() {
                                  _selectedType = 'expense';
                                  _selectedCategory = 'food';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedType == 'expense'
                                    ? _getTypeColor('expense')
                                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                    right: Radius.zero,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Expense',
                                style: AppTextStyles.body(context).copyWith(
                                  color: _selectedType == 'expense'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.transaction != null
                                  ? null // Disable in edit mode
                                  : () {
                                setState(() {
                                  _selectedType = 'income';
                                  _selectedCategory = 'salary';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedType == 'income'
                                    ? _getTypeColor('income')
                                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.zero,
                                    right: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Income',
                                style: AppTextStyles.body(context).copyWith(
                                  color: _selectedType == 'income'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context, labelText: 'Category'),
                        items: _categories.map((category) {
                          final categoryColor = _getCategoryColor(category);
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.capitalize()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        style: AppTextStyles.body(context),
                        dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
                        icon: AppInputStyles.dropdownProperties(context)['icon'],
                        menuMaxHeight: AppInputStyles.dropdownProperties(context)['menuMaxHeight'],
                        borderRadius: AppInputStyles.dropdownProperties(context)['borderRadius'],
                        elevation: AppInputStyles.dropdownProperties(context)['elevation'],
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: 'Description',
                          prefixIcon: const Icon(
                            Icons.description,
                            size: 24,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Field with Currency Symbol
                      TextFormField(
                        controller: _amountController,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: 'Amount ($displayCurrencySymbol)',
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            size: 24,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_displayCurrency != 'KGS')

                        // Auto-converted Amount in KGS
                        FutureBuilder<double>(
                          future: Future.value(
                            _displayCurrency != 'KGS'
                                ? _currencyApiService.getConversionRate(_displayCurrency, 'KGS')
                                : 1.0,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'Calculating amount in KGS...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'Error calculating amount in KGS: ${snapshot.error}',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              );
                            }
                            double conversionRate = snapshot.data ?? 1.0;
                            double amountInKGS = enteredAmount * conversionRate;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Amount in KGS: ${amountInKGS.toStringAsFixed(2)} $kgsSymbol',
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          },
                        ),

                      // Date Picker
                      ListTile(
                        title: Text(
                          "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                          style: AppTextStyles.body(context),
                        ),
                        trailing: Icon(
                          Icons.calendar_today,
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        ),
                        onTap: () => _selectDate(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        tileColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: AppButtonStyles.elevatedButton(context).copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    widget.transaction == null ? 'Add' : 'Update',
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}