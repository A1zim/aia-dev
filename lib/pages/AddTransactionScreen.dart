import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/models/category.dart';
import 'package:intl/intl.dart';
import 'package:aia_wallet/utils/scaling.dart'; // Import Scaling utility

import '../providers/transaction_provider.dart';

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
  Map<String, dynamic>? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _displayCurrency = 'Сом';
  late FocusNode _amountFocusNode;
  late FocusNode _descriptionFocusNode;

  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  static const List<String> _defaultCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
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

    _amountFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();

    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    _displayCurrency = currencyProvider.currency == 'KGS'
        ? 'Сом'
        : NumberFormat.simpleCurrency(name: currencyProvider.currency).currencySymbol;
    debugPrint('Initialized with currency: $_displayCurrency');

    if (widget.transaction == null) {
      _selectedType = 'expense';
      _descriptionController.text = '';
      _amountController.text = '';
      _selectedDate = DateTime.now();
      _selectedCategory = null;
    } else {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      _selectedType = widget.transaction!.type;
      _descriptionController.text = widget.transaction!.description ?? '';
      _amountController.text = widget.transaction!.originalAmount!.toStringAsFixed(2);
      _selectedDate = DateTime.parse(widget.transaction!.timestamp);
      _selectedCategory = {
        'id': widget.transaction!.customCategoryId,
        'name': widget.transaction!.defaultCategory ?? widget.transaction!.getCategory(transactionProvider),
        'type': widget.transaction!.type,
      };
    }

    _fetchCategories();
    _animationController.forward(); // Start animation on screen load
  }

  Future<void> _fetchCategories() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categories = transactionProvider.categories;
    setState(() {
      _allCategories = categories.map((category) => {
        'id': category.id,
        'name': category.name,
        'type': category.type,
        'isDefault': _defaultCategories.contains(category.name),
      }).toList();

      _expenseCategories = _allCategories.where((cat) => cat['type'] == 'expense').toList();
      _incomeCategories = _allCategories.where((cat) => cat['type'] == 'income').toList();

      if (_expenseCategories.isEmpty) {
        _expenseCategories.add({
          'id': null,
          'name': 'other_expense',
          'type': 'expense',
          'isDefault': true,
        });
        _allCategories.add({
          'id': null,
          'name': 'other_expense',
          'type': 'expense',
          'isDefault': true,
        });
      }
      if (_incomeCategories.isEmpty) {
        _incomeCategories.add({
          'id': null,
          'name': 'other_income',
          'type': 'income',
          'isDefault': true,
        });
        _allCategories.add({
          'id': null,
          'name': 'other_income',
          'type': 'income',
          'isDefault': true,
        });
      }

      if (_selectedCategory != null) {
        try {
          _selectedCategory = _allCategories.firstWhere(
                (cat) => cat['name'] == _selectedCategory!['name'] && cat['type'] == _selectedType,
            orElse: () => _selectedType == 'expense' ? _expenseCategories.first : _incomeCategories.first,
          );
        } catch (e) {
          _selectedCategory = _selectedType == 'expense' ? _expenseCategories.first : _incomeCategories.first;
        }
      } else {
        _selectedCategory = _selectedType == 'expense' ? _expenseCategories.first : _incomeCategories.first;
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Builder(
        builder: (innerContext) => _CustomTransactionCalendarDialog(
          parentState: this,
        ),
      ),
    );
  }

  void _adjustDateByDay(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      final today = DateTime.now();
      if (_selectedDate.isAfter(today)) {
        _selectedDate = DateTime(today.year, today.month, today.day);
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final String transactionCurrency = currencyProvider.currency;
      final double exchangeRate = currencyProvider.exchangeRate;
      debugPrint('Saving transaction with currency: $transactionCurrency, exchangeRate: $exchangeRate');

      try {
        final double enteredAmount = double.parse(_amountController.text);
        final double amountInKGS = transactionCurrency == 'KGS' ? enteredAmount : enteredAmount / exchangeRate;
        debugPrint('Entered amount: $enteredAmount, Converted to KGS: $amountInKGS');

        final transaction = Transaction(
          id: widget.transaction?.id,
          type: _selectedType,
          defaultCategory: _selectedCategory!['isDefault'] ? _selectedCategory!['name'] : null,
          customCategoryId: !_selectedCategory!['isDefault'] ? _selectedCategory!['id'] : null,
          amount: amountInKGS,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          timestamp: _selectedDate.toUtc().toIso8601String(),
          originalCurrency: transactionCurrency,
          originalAmount: enteredAmount,
        );

        if (widget.transaction == null) {
          await transactionProvider.addTransaction(transaction);
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: AppLocalizations.of(context)!.transactionAdded,
              isError: false,
            );
            Navigator.pop(context, {
              'success': true,
              'message': AppLocalizations.of(context)!.transactionAdded,
            });
          }
        } else {
          await transactionProvider.updateTransaction(transaction);
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: AppLocalizations.of(context)!.transactionUpdated,
              isError: false,
            );
            Navigator.pop(context, {
              'success': true,
              'message': AppLocalizations.of(context)!.transactionUpdated,
            });
          }
        }
      } catch (e) {
        if (mounted) {
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

  Color _getCategoryColor(String categoryName) {
    final Map<String, Color> categoryColors = {
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
      'unknown': const Color(0xFFB0BEC5),
    };

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryLower = categoryName.toLowerCase();

    // Check if the category is a default category
    if (categoryColors.containsKey(categoryLower)) {
      return categoryColors[categoryLower]!;
    }

    // For custom categories, use the color from TransactionProvider
    return transactionProvider.customCategoryColors[categoryLower] ?? const Color(0xFFB0BEC5);
  }

  Color _getTypeColor(String type) {
    const typeColors = {'expense': Color(0xFFEF5350), 'income': Color(0xFF4CAF50)};
    return typeColors[type] ?? Colors.grey.withOpacity(0.8);
  }

  String _getCategoryDisplayName(Map<String, dynamic> category) {
    if (_defaultCategories.contains(category['name'])) {
      return AppLocalizations.of(context)!.getCategoryName(category['name']);
    }
    return category['name'];
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    final displayCurrencySymbol = NumberFormat.simpleCurrency(name: _displayCurrency).currencySymbol;
    List<Map<String, dynamic>> _categories = _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

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
              padding: EdgeInsets.symmetric(
                horizontal: Scaling.scalePadding(16.0),
                vertical: Scaling.scalePadding(10.0),
              ),
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
                        size: Scaling.scaleIcon(24),
                      ),
                    ),
                    SizedBox(width: Scaling.scalePadding(12)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          height: Scaling.scale(40),
                          width: Scaling.scale(40),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'MON',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: 'ey',
                                style: TextStyle(
                                  fontSize: Scaling.scaleFont(24),
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
              margin: EdgeInsets.only(top: Scaling.scalePadding(8.0)),
              child: Center(
                child: Text(
                  widget.transaction == null
                      ? AppLocalizations.of(context)!.addTransaction
                      : AppLocalizations.of(context)!.editTransaction,
                  style: AppTextStyles.heading(context).copyWith(fontSize: Scaling.scaleFont(18)),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: Scaling.scale(1),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Scaling.scalePadding(16.0),
                vertical: Scaling.scalePadding(8.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _adjustDateByDay(-1),
                    icon: Icon(
                      Icons.arrow_left,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      size: Scaling.scaleIcon(36),
                      weight: 700,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.date,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: Scaling.scaleFont(16),
                          ),
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              fontSize: Scaling.scaleFont(16),
                            ),
                          ),
                        ),
                        SizedBox(width: Scaling.scalePadding(8)),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: Scaling.scalePadding(12),
                              vertical: Scaling.scalePadding(8),
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            size: Scaling.scaleIcon(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      if (_selectedDate.isBefore(today)) {
                        _adjustDateByDay(1);
                      }
                    },
                    icon: Icon(
                      Icons.arrow_right,
                      color: _selectedDate.isBefore(DateTime.now())
                          ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                          : (isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3)),
                      size: Scaling.scaleIcon(36),
                      weight: 700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Scaling.scalePadding(16.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          if (widget.transaction == null) {
                            setState(() {
                              _selectedType = 'expense';
                              _selectedCategory = _expenseCategories.first;
                            });
                            _animationController.forward(from: 0);
                          }
                        },
                        child: Container(
                          width: Scaling.scale(90),
                          height: Scaling.scale(40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Scaling.scale(20)),
                            color: _selectedType == 'expense'
                                ? _getTypeColor('expense').withOpacity(0.8 + 0.2 * _animation.value)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: Scaling.scaleIcon(18),
                                color: _selectedType == 'expense'
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              SizedBox(width: Scaling.scalePadding(4)),
                              Text(
                                AppLocalizations.of(context)!.expense,
                                style: TextStyle(
                                  color: _selectedType == 'expense'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: Scaling.scaleFont(14),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: Scaling.scalePadding(16)),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          if (widget.transaction == null) {
                            setState(() {
                              _selectedType = 'income';
                              _selectedCategory = _incomeCategories.first;
                            });
                            _animationController.forward(from: 0);
                          }
                        },
                        child: Container(
                          width: Scaling.scale(90),
                          height: Scaling.scale(40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Scaling.scale(20)),
                            color: _selectedType == 'income'
                                ? _getTypeColor('income').withOpacity(0.8 + 0.2 * _animation.value)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: Scaling.scaleIcon(18),
                                color: _selectedType == 'income'
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary),
                              ),
                              SizedBox(width: Scaling.scalePadding(4)),
                              Text(
                                AppLocalizations.of(context)!.income,
                                style: TextStyle(
                                  color: _selectedType == 'income'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: Scaling.scaleFont(14),
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
                padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: '${AppLocalizations.of(context)!.amount} ($displayCurrencySymbol)',
                          prefixIcon: Icon(Icons.attach_money, size: Scaling.scaleIcon(24)),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: Scaling.scalePadding(16),
                            horizontal: Scaling.scalePadding(12),
                          ),
                        ),
                        style: TextStyle(fontSize: Scaling.scaleFont(16)),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (value) => value == null || value.isEmpty
                            ? AppLocalizations.of(context)!.amountRequired
                            : double.tryParse(value) == null || double.parse(value) <= 0
                            ? AppLocalizations.of(context)!.amountInvalid
                            : null,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_descriptionFocusNode),
                      ),
                      SizedBox(height: Scaling.scalePadding(16)),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedCategory,
                        decoration: AppInputStyles.dropdown(context, labelText: AppLocalizations.of(context)!.category).copyWith(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: Scaling.scalePadding(16),
                            horizontal: Scaling.scalePadding(12),
                          ),
                        ),
                        items: _categories.map((category) => DropdownMenuItem<Map<String, dynamic>>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: Scaling.scale(12),
                                height: Scaling.scale(12),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category['name']),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: Scaling.scalePadding(8)),
                              Text(
                                _getCategoryDisplayName(category),
                                style: TextStyle(fontSize: Scaling.scaleFont(16)),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                        style: AppTextStyles.body(context).copyWith(fontSize: Scaling.scaleFont(16)),
                        dropdownColor: AppInputStyles.dropdownProperties(context)['dropdownColor'],
                        icon: Icon(
                          AppInputStyles.dropdownProperties(context)['icon'].icon,
                          size: Scaling.scaleIcon(24),
                        ),
                        menuMaxHeight: Scaling.scale(AppInputStyles.dropdownProperties(context)['menuMaxHeight']),
                        borderRadius: BorderRadius.circular(
                          Scaling.scale(
                            (AppInputStyles.dropdownProperties(context)['borderRadius'] is double)
                                ? AppInputStyles.dropdownProperties(context)['borderRadius']
                                : 8.0, // Fallback to a default double value if not a double
                          ),
                        ),
                        elevation: AppInputStyles.dropdownProperties(context)['elevation'],
                      ),
                      SizedBox(height: Scaling.scalePadding(16)),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        decoration: AppInputStyles.textField(context).copyWith(
                          labelText: AppLocalizations.of(context)!.description,
                          prefixIcon: Icon(Icons.description, size: Scaling.scaleIcon(24)),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: Scaling.scalePadding(16),
                            horizontal: Scaling.scalePadding(12),
                          ),
                        ),
                        style: TextStyle(fontSize: Scaling.scaleFont(16)),
                        validator: null,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: Scaling.scalePadding(24)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: Scaling.scalePadding(16)),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: Scaling.scale(4),
                          )
                              : Text(
                            AppLocalizations.of(context)!.confirm,
                            style: TextStyle(
                              fontSize: Scaling.scaleFont(16),
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
          ],
        ),
      ),
    );
  }
}

class _CustomTransactionCalendarDialog extends StatefulWidget {
  final _AddTransactionScreenState parentState;

  const _CustomTransactionCalendarDialog({required this.parentState});

  @override
  __CustomTransactionCalendarDialogState createState() => __CustomTransactionCalendarDialogState();
}

class __CustomTransactionCalendarDialogState extends State<_CustomTransactionCalendarDialog> {
  late DateTime _calendarDate;

  @override
  void initState() {
    super.initState();
    _calendarDate = widget.parentState._selectedDate;
  }

  void _shiftCalendarMonth(int direction) {
    final now = DateTime.now();
    final nextMonth = DateTime(_calendarDate.year, _calendarDate.month + direction, 1);
    if (direction > 0 && (nextMonth.isAfter(now) && !(nextMonth.month == now.month && nextMonth.year == now.year))) {
      return;
    }
    setState(() {
      _calendarDate = nextMonth;
    });
  }

  void _setDateFromCalendarTap(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isAfter(today)) {
      return;
    }

    widget.parentState.setState(() {
      widget.parentState._selectedDate = date;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12.0)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_left,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: Scaling.scaleIcon(24),
                  ),
                  onPressed: () => _shiftCalendarMonth(-1),
                ),
                Text(
                  '${localizations.getMonthName(_calendarDate.month)}, ${_calendarDate.year}',
                  style: AppTextStyles.subheading(context).copyWith(fontSize: Scaling.scaleFont(16)),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: Scaling.scaleIcon(24),
                  ),
                  onPressed: () {
                    final now = DateTime.now();
                    final nextMonth = DateTime(_calendarDate.year, _calendarDate.month + 1, 1);
                    if (nextMonth.isAfter(now) && !(nextMonth.month == now.month && nextMonth.year == now.year)) {
                      return;
                    }
                    _shiftCalendarMonth(1);
                  },
                ),
              ],
            ),
            _buildCalendar(context),
            SizedBox(height: Scaling.scalePadding(16)),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Scaling.scale(8)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: Scaling.scalePadding(16),
                  vertical: Scaling.scalePadding(8),
                ),
              ),
              child: Text(
                localizations.close,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Scaling.scaleFont(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDayOfMonth = DateTime(_calendarDate.year, _calendarDate.month, 1);
    final lastDayOfMonth = DateTime(_calendarDate.year, _calendarDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday;
    final startingOffset = (firstDayWeekday - 1) % 7;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekdays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Scaling.scaleFont(14),
                ),
              ),
            ),
          )).toList(),
        ),
        SizedBox(height: Scaling.scalePadding(8)),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          childAspectRatio: 1,
          children: List.generate(startingOffset + daysInMonth, (index) {
            if (index < startingOffset) return const SizedBox.shrink();
            final day = index - startingOffset + 1;
            final date = DateTime(_calendarDate.year, _calendarDate.month, day);
            final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
            final isFuture = date.isAfter(today);
            final isSelected = date.day == widget.parentState._selectedDate.day &&
                date.month == widget.parentState._selectedDate.month &&
                date.year == widget.parentState._selectedDate.year;

            return GestureDetector(
              onTap: isFuture ? null : () => _setDateFromCalendarTap(date),
              child: Container(
                margin: EdgeInsets.all(Scaling.scalePadding(2)),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkAccent.withOpacity(0.5)
                      : AppColors.lightAccent.withOpacity(0.5))
                      : (isToday
                      ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkAccent.withOpacity(0.3)
                      : AppColors.lightAccent.withOpacity(0.3))
                      : null),
                  borderRadius: BorderRadius.circular(Scaling.scale(8)),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isFuture
                          ? (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary.withOpacity(0.3)
                          : AppColors.lightTextSecondary.withOpacity(0.3))
                          : (isSelected || isToday
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          : null),
                      fontWeight: isSelected || isToday ? FontWeight.bold : null,
                      fontSize: Scaling.scaleFont(14),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}