import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'dart:io';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

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
  String _displayCurrency = 'KGS';

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
      _descriptionController.text = widget.transaction!.description;
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = DateTime.parse(widget.transaction!.timestamp);

      if (widget.transaction!.originalAmount != null && widget.transaction!.originalCurrency != null) {
        _amountController.text = widget.transaction!.originalAmount!.toStringAsFixed(2);
        _displayCurrency = widget.transaction!.originalCurrency!;
      } else {
        double amountInCurrentCurrency = widget.transaction!.amount;
        if (currencyProvider.currency != 'KGS') {
          try {
            double conversionRate = _currencyApiService.getConversionRate('KGS', currencyProvider.currency);
            amountInCurrentCurrency = widget.transaction!.amount * conversionRate;
          } catch (e) {
            print('Error converting amount for edit: $e');
            _displayCurrency = 'KGS';
          }
        }
        _amountController.text = amountInCurrentCurrency.toStringAsFixed(2);
        _displayCurrency = currencyProvider.currency;
      }
    } else {
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

      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final String transactionCurrency = widget.transaction != null ? _displayCurrency : currencyProvider.currency;

      try {
        final double enteredAmount = double.parse(_amountController.text);

        double amountInKGS;
        double conversionRate;
        if (transactionCurrency == 'KGS') {
          amountInKGS = enteredAmount;
          conversionRate = 1.0;
        } else {
          conversionRate = _currencyApiService.getConversionRate(transactionCurrency, 'KGS');
          amountInKGS = enteredAmount * conversionRate;

          if (transactionCurrency == currencyProvider.currency && conversionRate != currencyProvider.exchangeRate) {
            print('Warning: CurrencyProvider exchange rate (${currencyProvider.exchangeRate}) does not match CurrencyApiService rate ($conversionRate) for $transactionCurrency');
          }
        }

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
                ? AppLocalizations.of(context)!.transactionAdded
                : AppLocalizations.of(context)!.transactionUpdated,
          );

          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          if (e is SocketException) {
            errorMessage = AppLocalizations.of(context)!.networkError;
          } else if (e.toString().contains('Unsupported currency')) {
            final currencySymbol = _currencyApiService.getCurrencySymbol(transactionCurrency);
            errorMessage = 'The selected currency ($currencySymbol) is not supported.'; // Kept untranslated as it's dynamic
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

  Color _getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'food': const Color(0xFFEF5350),
      'transport': const Color(0xFF42A5F5),
      'housing': const Color(0xFFAB47BC),
      'utilities': const Color(0xFF26C6DA),
      'entertainment': const Color(0xFFFFCA28),
      'healthcare': const Color(0xFF4CAF50),
      'education': const Color(0xFFFF8A65),
      'shopping': const Color(0xFFD4E157),
      'other_expense': const Color(0xFF90A4AE),
      'salary': const Color(0xFF66BB6A),
      'gift': const Color(0xFFF06292),
      'interest': const Color(0xFF29B6F6),
      'other_income': const Color(0xFF78909C),
    };
    return categoryColors[category] ?? Colors.grey.withOpacity(0.8);
  }

  Color _getTypeColor(String type) {
    final Map<String, Color> typeColors = {
      'expense': const Color(0xFFEF5350),
      'income': const Color(0xFF4CAF50),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.transaction != null
                                  ? null
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
                                AppLocalizations.of(context)!.expense,
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
                                  ? null
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
                                AppLocalizations.of(context)!.income,
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

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context,
                            labelText: AppLocalizations.of(context)!.category),
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
                                Text(AppLocalizations.of(context)!.getCategoryName(category)),
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

                      TextFormField(
                        controller: _descriptionController,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: AppLocalizations.of(context)!.description,
                          prefixIcon: const Icon(
                            Icons.description,
                            size: 24,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.descriptionRequired;
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _amountController,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: '${AppLocalizations.of(context)!.amount} ($displayCurrencySymbol)',
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            size: 24,
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
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_displayCurrency != 'KGS')
                        FutureBuilder<double>(
                          future: Future.value(
                            _displayCurrency != 'KGS'
                                ? _currencyApiService.getConversionRate(_displayCurrency, 'KGS')
                                : 1.0,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  AppLocalizations.of(context)!.currencyConversionError(snapshot.error.toString()),
                                  style: AppTextStyles.body(context).copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              );
                            }
                            double conversionRate = snapshot.data ?? 1.0;
                            double amountInKGS = enteredAmount * conversionRate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                '${AppLocalizations.of(context)!.amountInKGS}: ${amountInKGS.toStringAsFixed(2)} $kgsSymbol',
                                style: AppTextStyles.body(context).copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          },
                        ),

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
                    widget.transaction == null
                        ? AppLocalizations.of(context)!.add
                        : AppLocalizations.of(context)!.update,
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