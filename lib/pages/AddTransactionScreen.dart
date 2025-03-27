import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
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
      // Edit mode: Populate fields with transaction data
      _descriptionController.text = widget.transaction!.description;
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = DateTime.parse(widget.transaction!.timestamp);

      // Determine the amount to display in the TextFormField
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      if (widget.transaction!.originalAmount != null && widget.transaction!.originalCurrency != null) {
        // Use originalAmount and originalCurrency if available
        _amountController.text = widget.transaction!.originalAmount!.toStringAsFixed(2);
        _displayCurrency = widget.transaction!.originalCurrency!;
      } else {
        // Fallback to amount in KGS and convert to current currency
        double amountInCurrentCurrency = widget.transaction!.amount;
        if (currencyProvider.currency != 'KGS') {
          amountInCurrentCurrency = widget.transaction!.amount * currencyProvider.exchangeRate;
        }
        _amountController.text = amountInCurrentCurrency.toStringAsFixed(2);
        _displayCurrency = currencyProvider.currency;
      }
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
        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        final double enteredAmount = double.parse(_amountController.text);

        // Determine the currency of the entered amount
        String transactionCurrency = widget.transaction != null ? _displayCurrency : currencyProvider.currency;

        // Convert the entered amount to KGS
        double amountInKGS;
        if (transactionCurrency == 'KGS') {
          amountInKGS = enteredAmount;
        } else {
          // Find the exchange rate for the transaction's currency
          double exchangeRate = currencyProvider.exchangeRate;
          if (widget.transaction != null && _displayCurrency != currencyProvider.currency) {
            // If editing and the display currency isn't the current currency,
            // we need the exchange rate from the display currency to KGS.
            // For simplicity, we assume the exchange rate in CurrencyProvider
            // is always relative to KGS, so we can use it.
            // If the backend provided historical rates, we'd need to fetch the rate
            // for _displayCurrency at the time of the transaction.
            exchangeRate = currencyProvider.getExchangeRateForCurrency(_displayCurrency);
          }
          amountInKGS = enteredAmount / exchangeRate;
        }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    List<String> _categories =
    _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    // Calculate the amount in KGS for display
    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    double amountInKGS = enteredAmount;
    if (_displayCurrency != 'KGS') {
      double exchangeRate = currencyProvider.getExchangeRateForCurrency(_displayCurrency);
      amountInKGS = enteredAmount / exchangeRate;
    }

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
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: AppInputStyles.dropdown(context, labelText: 'Type'),
                        items: ['expense', 'income']
                            .map((type) => AppInputStyles.dropdownMenuItem(context, type, type.capitalize()))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _selectedCategory = _selectedType == 'expense' ? 'food' : 'salary';
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

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context, labelText: 'Category'),
                        items: _categories
                            .map((category) => AppInputStyles.dropdownMenuItem(context, category, category.capitalize()))
                            .toList(),
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

                      TextFormField(
                        controller: _amountController,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: 'Amount ($_displayCurrency)',
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Amount in KGS: ${amountInKGS.toStringAsFixed(2)} KGS',
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),

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

extension CurrencyProviderExtension on CurrencyProvider {
  double getExchangeRateForCurrency(String currency) {
    // In a real app, this might fetch the exchange rate for the specific currency
    // For now, we assume the exchangeRate in CurrencyProvider is always relative to KGS
    return currency == this.currency ? this.exchangeRate : 1.0;
  }
}