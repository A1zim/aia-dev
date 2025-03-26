import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'dart:io'; // For SocketException
import 'package:personal_finance/theme/styles.dart'; // Import the styles file
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';
import 'package:personal_finance/generated/app_localizations.dart';

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

  final ApiService _apiService = ApiService();

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
    if (widget.transaction != null) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.originalAmount?.toString() ?? widget.transaction!.amount.toString();
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the CurrencyProvider to access the selected currency and exchange rate
        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

        // Parse the entered amount (assumed to be in the selected currency)
        final double enteredAmount = double.parse(_amountController.text);

        // Convert the entered amount to KGS (Soms)
        double amountInKGS;
        if (currencyProvider.currency == 'KGS') {
          amountInKGS = enteredAmount; // No conversion needed for KGS
        } else {
          // The exchange rate in CurrencyProvider is KGS -> selected currency
          // To convert from selected currency to KGS, we divide by the exchange rate
          amountInKGS = enteredAmount / currencyProvider.exchangeRate;
        }

        final transaction = Transaction(
          id: widget.transaction?.id ?? 0,
          user: widget.transaction?.user ?? 0,
          type: _selectedType,
          category: _selectedCategory,
          amount: amountInKGS, // Save the amount in KGS
          description: _descriptionController.text,
          timestamp: _selectedDate.toIso8601String(),
          username: widget.transaction?.username ?? '',
          originalCurrency: currencyProvider.currency, // Store the currency in which the amount was entered
          originalAmount: enteredAmount, // Store the original amount before conversion
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
                    ? AppLocalizations.of(context)!.transactionAdded
                    : AppLocalizations.of(context)!.transactionUpdated,
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
            errorMessage = AppLocalizations.of(context)!.networkError;
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
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    List<String> _categories =
    _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    // Calculate the converted amount in KGS for display
    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    double amountInKGS = enteredAmount;
    if (currencyProvider.currency != 'KGS') {
      amountInKGS = enteredAmount / currencyProvider.exchangeRate;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? AppLocalizations.of(context)!.addTransaction
              : AppLocalizations.of(context)!.editTransaction,
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
                      labelText: AppLocalizations.of(context)!.description,
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
                        return AppLocalizations.of(context)!.descriptionRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    decoration: AppInputStyles.textField(context).copyWith(
                      labelText: '${AppLocalizations.of(context)!.amount} (${currencyProvider.currency})',
                      prefixIcon: const Icon(Icons.attach_money),
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
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.amountRequired;
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return AppLocalizations.of(context)!.amountInvalid;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Update the converted amount display
                    },
                  ),
                  const SizedBox(height: 16),

                  // Display the converted amount in KGS
                  if (currencyProvider.currency != 'KGS')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        '${AppLocalizations.of(context)!.amountInKGS}: ${amountInKGS.toStringAsFixed(2)} KGS',
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),

                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: AppInputStyles.dropdown(context, labelText: AppLocalizations.of(context)!.type),
                    items: ['expense', 'income']
                        .map((type) => AppInputStyles.dropdownMenuItem(context, type, type.capitalize()))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _selectedCategory = _selectedType == 'expense' ? 'food' : 'salary';
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

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: AppInputStyles.dropdown(context, labelText: AppLocalizations.of(context)!.category),
                    items: _categories
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
                      "${AppLocalizations.of(context)!.date}: ${_selectedDate.toLocal().toString().split(' ')[0]}",
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
                        widget.transaction == null
                            ? AppLocalizations.of(context)!.add
                            : AppLocalizations.of(context)!.update,
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