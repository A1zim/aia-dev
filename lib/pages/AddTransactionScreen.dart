// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'dart:io'; // For SocketException
import 'package:personal_finance/theme/styles.dart'; // Import the styles file
import 'package:personal_finance/models/currency_converter.dart'; // Add this import

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
  String _currentCurrency = 'KGS'; // Add this field

  final ApiService _apiService = ApiService();

  // Fix: Make the lists final and define them as static constants
  static final List<String> expenseCategories = [
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

  static final List<String> incomeCategories = [
    'salary',
    'gift',
    'interest',
    'other_income',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // Add this method call
    
    if (widget.transaction != null) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = DateTime.parse(widget.transaction!.timestamp);
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

  // Add this method
  Future<void> _loadCurrency() async {
    final currency = await CurrencyConverter.getPreferredCurrency();
    setState(() {
      _currentCurrency = currency;
    });
  }

 Future<void> _submit() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure proper decimal handling
      double amount = double.parse(_amountController.text);
      
      // Don't round in a way that might eliminate small values
      amount = double.parse(amount.toStringAsFixed(2));

      // If the current currency is not KGS, convert the amount to KGS for storage
      if (_currentCurrency != 'KGS') {
        double rate = await CurrencyConverter.getConversionRate(_currentCurrency, 'KGS');
        amount = amount * rate;
        amount = double.parse(amount.toStringAsFixed(2));
      }

      final transaction = Transaction(
        id: widget.transaction?.id ?? 0,
        user: widget.transaction?.user ?? 0,
        type: _selectedType,
        category: _selectedCategory,
        amount: amount, // Use the rounded amount
        description: _descriptionController.text,
        timestamp: _selectedDate.toIso8601String(),
        username: widget.transaction?.username ?? '',
      );

      if (widget.transaction == null) {
        await _apiService.addTransaction(transaction);
      } else {
        await _apiService.updateTransaction(widget.transaction!.id, transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction == null
                  ? 'Transaction added successfully!'
                  : 'Transaction updated successfully!',
              style: AppTextStyles.body(context),
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (e is SocketException) {
          errorMessage =
              'Network error: Unable to reach the server. Please check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: AppTextStyles.body(context),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Fix: Use the static constants instead of instance variables
    final categories = _selectedType == 'expense' ? expenseCategories : incomeCategories;

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: AppInputStyles.textField(context).copyWith(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          width: 2,
                        ),
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

                  // Amount Field - Update to show currency
                  TextFormField(
                    controller: _amountController,
                    decoration: AppInputStyles.textField(context).copyWith(
                      labelText: 'Amount ($_currentCurrency)', // Add currency to label
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: _currentCurrency == 'KGS' ? 'сом' : null,
                      hintText: 'Any positive amount (e.g., 0.5, 10, 100)', // Add hint for small amounts
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // Explicitly enable decimal input
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      try {
                        double amount = double.parse(value);
                        if (amount <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: AppInputStyles.dropdown(context, labelText: 'Type'),
                    items: ['expense', 'income']
                        .map((type) => AppInputStyles.dropdownMenuItem(context, type, type.capitalize()))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        // Fix: Use the first category from the appropriate list
                        _selectedCategory = _selectedType == 'expense' 
                            ? expenseCategories.first 
                            : incomeCategories.first;
                      });
                    },
                    style: AppInputStyles.dropdownProperties(context)['style'],
                    dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
                    icon: AppInputStyles.dropdownProperties(context)['icon'],
                    menuMaxHeight: AppInputStyles.dropdownProperties(context)['menuMaxHeight'],
                    borderRadius: AppInputStyles.dropdownProperties(context)['borderRadius'],
                    elevation: AppInputStyles.dropdownProperties(context)['elevation'],
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown - Fix: Use categories variable defined above
                  DropdownButtonFormField<String>(
                    value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                    decoration: AppInputStyles.dropdown(context, labelText: 'Category'),
                    items: categories
                        .map((category) => AppInputStyles.dropdownMenuItem(context, category, category.capitalize()))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    style: AppInputStyles.dropdownProperties(context)['style'],
                    dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
                    icon: AppInputStyles.dropdownProperties(context)['icon'],
                    menuMaxHeight: AppInputStyles.dropdownProperties(context)['menuMaxHeight'],
                    borderRadius: AppInputStyles.dropdownProperties(context)['borderRadius'],
                    elevation: AppInputStyles.dropdownProperties(context)['elevation'],
                  ),
                  const SizedBox(height: 16),

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
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function for capitalization
extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}