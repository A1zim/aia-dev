import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:flutter/services.dart';
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
  late FocusNode _descriptionFocusNode;
  late FocusNode _amountFocusNode;

  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();

  List<String> _expenseCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
  ];

  List<String> _incomeCategories = [
    'salary', 'gift', 'interest', 'other_income',
  ];

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

    _descriptionFocusNode = FocusNode();
    _amountFocusNode = FocusNode();

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
      _amountController.text = '';
      _displayCurrency = currencyProvider.currency;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    _descriptionFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now(); // Use current date as the max selectable date
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Minimum selectable date
      lastDate: today, // Maximum selectable date is today
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        // Strip the time component, keeping only the date
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        print('Selected date updated to: $_selectedDate');
      });
    }
  }

  Future<void> _submit() async {
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

        amountInKGS = double.parse(amountInKGS.toStringAsFixed(2));

        final Map<String, dynamic> transactionData = {
          'type': _selectedType,
          'category': _selectedCategory,
          'amount': amountInKGS,
          'description': _descriptionController.text,
          'originalCurrency': transactionCurrency, // Match JSON key
          'originalAmount': enteredAmount,         // Match JSON key
          'timestamp': _selectedDate.toUtc().toIso8601String(), // Ensure UTC with 'Z'
        };

        print('Submitting transaction: $transactionData');

        if (widget.transaction == null) {
          // For new transactions, assume user and username are handled elsewhere (e.g., in ApiService)
          await _apiService.addTransaction(transactionData);
        } else {
          // For updates, include all required fields from the original transaction
          transactionData['id'] = widget.transaction!.id;
          transactionData['user'] = widget.transaction!.user; // Preserve original user
          transactionData['username'] = widget.transaction!.username; // Preserve original username

          // Create a Transaction object from the updated data
          final Transaction updatedTransaction = Transaction.fromJson(transactionData);
          await _apiService.updateTransaction(widget.transaction!.id, updatedTransaction);
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
          print('Error submitting transaction: $e');
          NotificationService.showNotification(
            context,
            message: '${AppLocalizations.of(context)!.transactionFailed}: $e',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final displayCurrencySymbol = _currencyApiService.getCurrencySymbol(_displayCurrency);
    final kgsSymbol = _currencyApiService.getCurrencySymbol('KGS');
    List<String> _categories = _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

    return Scaffold(
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
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // Always enabled
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent, // Keep color consistent
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${AppLocalizations.of(context)!.date}: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context, labelText: AppLocalizations.of(context)!.category),
                        items: _categories.map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category),
                                  shape: BoxShape.circle,
                                ),
                              ),
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
                        focusNode: _descriptionFocusNode,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: AppLocalizations.of(context)!.description,
                          prefixIcon: const Icon(Icons.description, size: 24),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? AppLocalizations.of(context)!.descriptionRequired
                            : null,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_amountFocusNode),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: '${AppLocalizations.of(context)!.amount} ($displayCurrencySymbol)',
                          prefixIcon: const Icon(Icons.attach_money, size: 24),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (value) => value == null || value.isEmpty
                            ? AppLocalizations.of(context)!.amountRequired
                            : double.tryParse(value) == null || double.parse(value) <= 0
                            ? AppLocalizations.of(context)!.amountInvalid
                            : null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      if (_displayCurrency != 'KGS')
                        FutureBuilder<double>(
                          future: Future.value(_currencyApiService.getConversionRate(_displayCurrency, 'KGS')),
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            AppLocalizations.of(context)!.confirm,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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
