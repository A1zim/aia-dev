import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/models/transaction.dart';
import 'dart:io'; // For SocketException
import 'package:personal_finance/theme/styles.dart'; // Import the styles file
import 'package:personal_finance/localization/app_localizations.dart'; // Импорт локализации

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

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final transaction = Transaction(
          id: widget.transaction?.id ?? 0,
          user: widget.transaction?.user ?? 0,
          type: _selectedType,
          category: _selectedCategory,
          amount: double.parse(_amountController.text),
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
                    ? localizations.transactionAddedSuccessfully
                    : localizations.transactionUpdatedSuccessfully,
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
            errorMessage = localizations.networkError;
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
    final localizations = AppLocalizations.of(context);
    List<String> _categories =
        _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? localizations.addTransaction
              : localizations.editTransaction,
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
                      labelText: localizations.description,
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
                        return localizations.pleaseEnterDescription;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    decoration: AppInputStyles.textField(context).copyWith(
                      labelText: localizations.amount,
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
                        return localizations.pleaseEnterAmount;
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return localizations.pleaseEnterValidAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: AppInputStyles.dropdown(context, labelText: localizations.type),
                    items: ['expense', 'income']
                        .map((type) => AppInputStyles.dropdownMenuItem(
                              context,
                              type,
                              type == 'expense' ? localizations.expense : localizations.income,
                            ))
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
                    decoration: AppInputStyles.dropdown(context, labelText: localizations.category),
                    items: _categories
                        .map((category) => AppInputStyles.dropdownMenuItem(
                              context,
                              category,
                              _getCategoryTranslation(category, localizations),
                            ))
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
                      "${localizations.date}: ${_selectedDate.toLocal().toString().split(' ')[0]}",
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
                              widget.transaction == null ? localizations.add : localizations.update,
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

  // Метод для получения перевода категории
  String _getCategoryTranslation(String category, AppLocalizations localizations) {
    switch (category) {
      case 'food':
        return localizations.food;
      case 'transport':
        return localizations.transport;
      case 'housing':
        return localizations.housing;
      case 'utilities':
        return localizations.utilities;
      case 'entertainment':
        return localizations.entertainment;
      case 'healthcare':
        return localizations.healthcare;
      case 'education':
        return localizations.education;
      case 'shopping':
        return localizations.shopping;
      case 'other_expense':
        return localizations.otherExpense;
      case 'salary':
        return localizations.salary;
      case 'gift':
        return localizations.gift;
      case 'interest':
        return localizations.interest;
      case 'other_income':
        return localizations.otherIncome;
      default:
        return localizations.unknown;
    }
  }
}

// Helper function for capitalization
extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}