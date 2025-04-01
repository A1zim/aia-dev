import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _displayCurrency = 'KGS';
  late FocusNode _descriptionFocusNode; // Add FocusNode for description field
  late FocusNode _amountFocusNode; // Add FocusNode for amount field

  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();

  List<String> _expenseCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
  ];

  List<String> _incomeCategories = [
    'salary', 'gift', 'interest', 'other_income',
  ];

  String? _operation;
  double? _operationValue;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _descriptionFocusNode = FocusNode(); // Initialize FocusNode
    _amountFocusNode = FocusNode(); // Initialize FocusNode

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
      _amountController.text = '0';
      _displayCurrency = currencyProvider.currency;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    _descriptionFocusNode.dispose(); // Dispose FocusNode
    _amountFocusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Set today as March 31, 2025, for testing purposes
    final DateTime today = DateTime(2025, 3, 31);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today, // Today is March 31, 2025
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        print('Selected date updated to: $_selectedDate');
      });
    }
  }

  Future<void> _submit() async {
    if (_operation != null && _operationValue != null) {
      _applyOperation();
    }

    double finalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (finalAmount <= 0) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.amountInvalid,
        isError: true,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final String transactionCurrency = widget.transaction != null ? _displayCurrency : currencyProvider.currency;

      try {
        final double enteredAmount = double.parse(_amountController.text);
        double amountInKGS = transactionCurrency == 'KGS'
            ? enteredAmount
            : enteredAmount * _currencyApiService.getConversionRate(transactionCurrency, 'KGS');

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

        print('Submitting transaction with timestamp: ${transaction.timestamp}');

        if (widget.transaction == null) {
          await _apiService.addTransaction(transaction);
        } else {
          await _apiService.updateTransaction(widget.transaction!.id, transaction);
        }

        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, {
            'success': true,
            'message': widget.transaction == null
                ? AppLocalizations.of(context)!.transactionAdded
                : AppLocalizations.of(context)!.transactionUpdated,
          });
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: AppLocalizations.of(context)!.transactionFailed,
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Color _getCategoryColor(String category) {
    const categoryColors = {
      'food': Color(0xFFEF5350),
      'transport': Color(0xFF42A5F5),
      'housing': Color(0xFFAB47BC),
      'utilities': Color(0xFF26C6DA),
      'entertainment': Color(0xFFFFCA28),
      'healthcare': Color(0xFF4CAF50),
      'education': Color(0xFFFF8A65),
      'shopping': Color(0xFFD4E157),
      'other_expense': Color(0xFF90A4AE),
      'salary': Color(0xFF66BB6A),
      'gift': Color(0xFFF06292),
      'interest': Color(0xFF29B6F6),
      'other_income': Color(0xFF78909C),
    };
    return categoryColors[category] ?? Colors.grey.withOpacity(0.8);
  }

  Color _getTypeColor(String type) {
    const typeColors = {'expense': Color(0xFFEF5350), 'income': Color(0xFF4CAF50)};
    return typeColors[type] ?? Colors.grey.withOpacity(0.8);
  }

  Widget _buildKeypadButton(String label, VoidCallback onPressed, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          border: Border.all(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [],
        ),
        child: Center(
          child: label == '⌫'
              ? Icon(Icons.backspace, size: 20, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
              : Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color != null
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }

  void _appendDigit(String digit) {
    setState(() {
      String currentText = _amountController.text;
      _amountController.text = currentText == '0' ? digit : currentText + digit;
    });
  }

  void _clearAll() => setState(() => _amountController.text = '0');

  void _backspace() {
    setState(() {
      String currentText = _amountController.text;
      _amountController.text = currentText.length > 1 ? currentText.substring(0, currentText.length - 1) : '0';
    });
  }

  void _setZeroAndPrepareAdd() {
    setState(() {
      _operationValue = double.tryParse(_amountController.text) ?? 0.0;
      _amountController.text = '0';
      _operation = 'add';
    });
  }

  void _setZeroAndPrepareSubtract() {
    setState(() {
      _operationValue = double.tryParse(_amountController.text) ?? 0.0;
      _amountController.text = '0';
      _operation = 'subtract';
    });
  }

  void _applyOperation() {
    setState(() {
      double currentInput = double.tryParse(_amountController.text) ?? 0.0;
      double originalAmount = _operationValue ?? 0.0;
      double newAmount = 0.0;

      if (_operation == 'add') {
        newAmount = originalAmount + currentInput;
      } else if (_operation == 'subtract') {
        newAmount = originalAmount - currentInput;
      }

      _amountController.text = newAmount == 0 ? '0' : newAmount.toStringAsFixed(2);
      _operationValue = null;
      _operation = null;
    });
  }

  bool _isKeyboardVisible() {
    // Check if the keyboard is visible by examining the bottom inset
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    List<String> _categories = _selectedType == 'expense' ? _expenseCategories : _incomeCategories;
    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final displayCurrencySymbol = _currencyApiService.getCurrencySymbol(_displayCurrency);
    final kgsSymbol = _currencyApiService.getCurrencySymbol('KGS');

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  widget.transaction == null
                      ? AppLocalizations.of(context)!.addTransaction
                      : AppLocalizations.of(context)!.editTransaction,
                  style: AppTextStyles.heading(context).copyWith(fontSize: 18),
                ),
              ),
            ),
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
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: widget.transaction != null
                                    ? null
                                    : () {
                                  setState(() {
                                    _selectedType = 'expense';
                                    _selectedCategory = 'food';
                                  });
                                  _animationController.forward(from: 0);
                                },
                                child: Container(
                                  width: 90,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _selectedType == 'expense'
                                        ? _getTypeColor('expense').withOpacity(0.8 + 0.2 * _animation.value)
                                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 18,
                                        color: _selectedType == 'expense'
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.expense,
                                        style: TextStyle(
                                          color: _selectedType == 'expense'
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: widget.transaction != null
                                    ? null
                                    : () {
                                  setState(() {
                                    _selectedType = 'income';
                                    _selectedCategory = 'salary';
                                  });
                                  _animationController.forward(from: 0);
                                },
                                child: Container(
                                  width: 90,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _selectedType == 'income'
                                        ? _getTypeColor('income').withOpacity(0.8 + 0.2 * _animation.value)
                                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 18,
                                        color: _selectedType == 'income'
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.income,
                                        style: TextStyle(
                                          color: _selectedType == 'income'
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context, labelText: AppLocalizations.of(context)!.category),
                        items: _categories.map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: _getCategoryColor(category), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.getCategoryName(category)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value!),
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
                        focusNode: _descriptionFocusNode, // Assign FocusNode
                        decoration: AppInputStyles.textField(context).copyWith(labelText: AppLocalizations.of(context)!.description, prefixIcon: const Icon(Icons.description, size: 24)),
                        validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.descriptionRequired : null,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode, // Assign FocusNode
                        decoration: AppInputStyles.textField(context).copyWith(labelText: '${AppLocalizations.of(context)!.amount} ($displayCurrencySymbol)', prefixIcon: const Icon(Icons.attach_money, size: 24)),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.amountRequired : double.tryParse(value) == null || double.parse(value) <= 0 ? AppLocalizations.of(context)!.amountInvalid : null,
                        readOnly: true, // Keep it read-only since we use the custom keypad
                      ),
                      const SizedBox(height: 16),
                      if (_displayCurrency != 'KGS')
                        FutureBuilder<double>(
                          future: Future.value(_currencyApiService.getConversionRate(_displayCurrency, 'KGS')),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(padding: EdgeInsets.only(top: 16.0), child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  AppLocalizations.of(context)!.currencyConversionError(snapshot.error.toString()),
                                  style: AppTextStyles.body(context).copyWith(color: Theme.of(context).colorScheme.error),
                                ),
                              );
                            }
                            double conversionRate = snapshot.data ?? 1.0;
                            double amountInKGS = enteredAmount * conversionRate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                '${AppLocalizations.of(context)!.amountInKGS}: ${amountInKGS.toStringAsFixed(2)} $kgsSymbol',
                                style: AppTextStyles.body(context).copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            );
                          },
                        ),
                      ListTile(
                        title: Text("${AppLocalizations.of(context)!.date}: ${_selectedDate.toLocal().toString().split(' ')[0]}", style: AppTextStyles.body(context)),
                        trailing: Icon(Icons.calendar_today, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                        onTap: () => _selectDate(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        tileColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Conditionally show the keypad based on keyboard visibility
            if (!_isKeyboardVisible())
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 1.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildKeypadButton('1', () => _appendDigit('1')),
                      _buildKeypadButton('2', () => _appendDigit('2')),
                      _buildKeypadButton('3', () => _appendDigit('3')),
                      _buildKeypadButton('⌫', _backspace),
                      _buildKeypadButton('4', () => _appendDigit('4')),
                      _buildKeypadButton('5', () => _appendDigit('5')),
                      _buildKeypadButton('6', () => _appendDigit('6')),
                      _buildKeypadButton('+', _setZeroAndPrepareAdd),
                      _buildKeypadButton('7', () => _appendDigit('7')),
                      _buildKeypadButton('8', () => _appendDigit('8')),
                      _buildKeypadButton('9', () => _appendDigit('9')),
                      _buildKeypadButton('-', _setZeroAndPrepareSubtract),
                      _buildKeypadButton('AC', _clearAll, color: Colors.orange),
                      _buildKeypadButton('0', () => _appendDigit('0')),
                      _buildKeypadButton('=', _applyOperation),
                      _buildKeypadButton('OK', _submit, color: Colors.blue),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}