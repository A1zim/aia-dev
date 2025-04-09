import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aia_wallet/pages/AddTransactionScreen.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/models/transaction.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/providers/transaction_provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/utils/scaling.dart';
import '../models/category.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  Set<int> _expandedIndices = {};

  static const List<String> _defaultCategories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other_expense',
    'salary', 'gift', 'interest', 'other_income',
  ];

  Future<void> _deleteTransaction(int id) async {
    try {
      await Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(id);
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.transactionDeleted,
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.deleteTransactionFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result is Map<String, dynamic> && result['success'] == true) {
      NotificationService.showNotification(
        context,
        message: result['message'],
      );
    }
  }

  Future<bool> _confirmDeleteTransaction(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.lightSurface, AppColors.lightBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
              border: Border.all(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteTransaction,
                    style: AppTextStyles.subheading(context),
                  ),
                  SizedBox(height: Scaling.scalePadding(8)),
                  Text(
                    AppLocalizations.of(context)!.deleteTransactionConfirm,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Scaling.scalePadding(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Scaling.scale(8)),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.yes,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Scaling.scaleFont(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CustomCalendarDialog();
      },
    );
  }

  double _convertAmount(Transaction transaction) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final preferredCurrency = transactionProvider.userFinances?.preferredCurrency ?? 'KGS';

    if (transaction.originalAmount != null &&
        transaction.originalCurrency != null &&
        transaction.originalCurrency == preferredCurrency) {
      return transaction.originalAmount!;
    }

    final double amountInKGS = transaction.amount;
    final double exchangeRate = currencyProvider.exchangeRate;
    return currencyProvider.currency == 'KGS' ? amountInKGS : amountInKGS * exchangeRate;
  }

  String _getCurrencySymbol() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currency = transactionProvider.userFinances?.preferredCurrency ?? 'KGS';
    return currency == 'KGS' ? 'Сом' : NumberFormat.simpleCurrency(name: currency).currencySymbol;
  }

  @override
  Widget build(BuildContext context) {
    Scaling.init(context); // Initialize scaling

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logoPath = themeProvider.getLogoPath(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    transactionProvider.groupTransactionsByDate(context);

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
                  children: [
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
                    SizedBox(width: Scaling.scalePadding(24)),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: Scaling.scalePadding(8.0)),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.transactionHistory,
                  style: AppTextStyles.heading(context).copyWith(
                    fontSize: Scaling.scaleFont(18),
                  ),
                ),
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300],
              thickness: 1,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await transactionProvider.loadData();
                },
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                child: transactionProvider.filteredTransactions.isEmpty
                    ? Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.noTransactionsFound,
                          style: AppTextStyles.body(context).copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : ListView.builder(
                  padding: EdgeInsets.only(top: Scaling.scalePadding(5)),
                  itemCount: (transactionProvider.dateFilter == 'Daily' ? 0 : transactionProvider.dateKeys.length) + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildFilterSection();
                    }
                    if (transactionProvider.dateFilter == 'Daily') {
                      return const SizedBox.shrink();
                    }
                    final dateIndex = index - 1;
                    final dateKey = transactionProvider.dateKeys[dateIndex];
                    final transactions = transactionProvider.groupedTransactions[dateKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Scaling.scalePadding(16.0),
                            vertical: Scaling.scalePadding(8.0),
                          ),
                          child: Text(
                            dateKey, // Localized "Today" or "Yesterday"
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: Scaling.scaleFont(14),
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        ...transactions.asMap().entries.map((entry) {
                          final transactionIndex = transactionProvider.filteredTransactions.indexOf(entry.value);
                          return _buildTransactionCard(
                            entry.value,
                            transactionIndex,
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (transactionProvider.dateFilter == 'Daily' && transactionProvider.filteredTransactions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: Scaling.scalePadding(80.0)),
                  itemCount: transactionProvider.filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactionProvider.filteredTransactions[index];
                    return _buildTransactionCard(transaction, index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isRightArrowDisabled = transactionProvider.dateFilter != 'Custom' &&
        transactionProvider.selectedEndDate != null &&
        !transactionProvider.selectedEndDate!.isBefore(today);

    return Padding(
      padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          transactionProvider.updateFilters(
                            filterExpense: !transactionProvider.filterExpense && transactionProvider.filterIncome
                                ? true
                                : !transactionProvider.filterExpense,
                          );
                        },
                        child: Container(
                          width: Scaling.scale(90),
                          height: Scaling.scale(40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Scaling.scale(20)),
                            color: transactionProvider.filterExpense
                                ? const Color(0xFFEF5350).withOpacity(0.8)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: Scaling.scaleIcon(18),
                                color: transactionProvider.filterExpense
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              SizedBox(width: Scaling.scalePadding(4)),
                              Text(
                                localizations!.expense,
                                style: TextStyle(
                                  color: transactionProvider.filterExpense
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: Scaling.scaleFont(14),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(16)),
                      GestureDetector(
                        onTap: () {
                          transactionProvider.updateFilters(
                            filterIncome: transactionProvider.filterExpense && !transactionProvider.filterIncome
                                ? true
                                : !transactionProvider.filterIncome,
                          );
                        },
                        child: Container(
                          width: Scaling.scale(90),
                          height: Scaling.scale(40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Scaling.scale(20)),
                            color: transactionProvider.filterIncome
                                ? const Color(0xFF4CAF50).withOpacity(0.8)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: Scaling.scaleIcon(18),
                                color: transactionProvider.filterIncome
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              SizedBox(width: Scaling.scalePadding(4)),
                              Text(
                                localizations!.income,
                                style: TextStyle(
                                  color: transactionProvider.filterIncome
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontSize: Scaling.scaleFont(14),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (transactionProvider.areFiltersApplied())
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: Scaling.scaleIcon(24),
                      ),
                      onPressed: () {
                        transactionProvider.clearFilters();
                      },
                    ),
                ],
              ),
              SizedBox(height: Scaling.scalePadding(12)),
              Row(
                children: [
                  if (transactionProvider.dateFilter != 'Custom')
                    IconButton(
                      onPressed: () => transactionProvider.shiftDateRange(-1),
                      icon: Icon(
                        Icons.arrow_left,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: Scaling.scaleIcon(36),
                        weight: 700,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Scaling.scalePadding(12.0)),
                        child: Text(
                          transactionProvider.getDateRangeDisplayText(context),
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: Scaling.scaleFont(16),
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (transactionProvider.dateFilter != 'Custom')
                    IconButton(
                      onPressed: isRightArrowDisabled ? null : () => transactionProvider.shiftDateRange(1),
                      icon: Icon(
                        Icons.arrow_right,
                        color: isRightArrowDisabled
                            ? (isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3))
                            : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                        size: Scaling.scaleIcon(36),
                        weight: 700,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      size: Scaling.scaleIcon(24),
                    ),
                    onPressed: _showCalendarDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedIndices.contains(index);
    final isIncome = transaction.type == 'income';
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final preferredCurrency = transactionProvider.userFinances?.preferredCurrency ?? 'KGS';
    final convertedAmount = _convertAmount(transaction);
    final currencySymbol = _getCurrencySymbol();

    String getCategoryDisplayName() {
      if (transaction.defaultCategory != null && _defaultCategories.contains(transaction.defaultCategory)) {
        return AppLocalizations.of(context)!.getCategoryName(transaction.defaultCategory!).capitalize();
      }
      if (transaction.customCategoryId != null) {
        final customCategory = transactionProvider.getCategoryById(transaction.customCategoryId!);
        return customCategory?.name.capitalize() ?? 'Unknown';
      }
      return transaction.getCategory(transactionProvider).capitalize();
    }

    String origCurrency = transaction.originalCurrency ?? '';

    return Semantics(
      label: '${isIncome ? "Income" : "Expense"} transaction, ${transaction.description ?? ''}, ${convertedAmount.toStringAsFixed(2)} $currencySymbol',
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(
          horizontal: Scaling.scalePadding(10),
          vertical: Scaling.scalePadding(6),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
        ),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIndices.remove(index);
              } else {
                _expandedIndices.add(index);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(Scaling.scale(12)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Scaling.scalePadding(16),
                    vertical: Scaling.scalePadding(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: Scaling.scale(24),
                        backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                          size: Scaling.scaleIcon(24),
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (transaction.description != null && transaction.description!.isNotEmpty)
                              Text(
                                transaction.description!,
                                style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              getCategoryDisplayName(),
                              style: AppTextStyles.body(context).copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Scaling.scalePadding(8)),
                      Text(
                        "${convertedAmount.toStringAsFixed(2)} $currencySymbol",
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: Scaling.scaleFont(16),
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        size: Scaling.scaleIcon(24),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Container(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    child: Padding(
                      padding: EdgeInsets.all(Scaling.scalePadding(16.0)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            AppLocalizations.of(context)!.description,
                            transaction.description ?? '',
                            context,
                          ),
                          SizedBox(height: Scaling.scalePadding(8)),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.category,
                            getCategoryDisplayName(),
                            context,
                          ),
                          SizedBox(height: Scaling.scalePadding(8)),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.amount,
                            "${convertedAmount.toStringAsFixed(2)} $currencySymbol",
                            context,
                            valueColor: isIncome ? Colors.green : Colors.red,
                          ),
                          SizedBox(height: Scaling.scalePadding(8)),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.type,
                            transaction.type == 'income'
                                ? AppLocalizations.of(context)!.income
                                : AppLocalizations.of(context)!.expense,
                            context,
                          ),
                          SizedBox(height: Scaling.scalePadding(8)),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.date,
                            DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction.timestamp)),
                            context,
                          ),
                          if (transaction.originalCurrency != null && transaction.originalAmount != null)
                            Padding(
                              padding: EdgeInsets.only(top: Scaling.scalePadding(8.0)),
                              child: _buildDetailRow(
                                AppLocalizations.of(context)!.original,
                                '${transaction.originalAmount!.toStringAsFixed(2)} ${CurrencyApiService().getCurrencySymbol(origCurrency)}',
                                context,
                              ),
                            ),
                          SizedBox(height: Scaling.scalePadding(8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => _editTransaction(transaction),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Scaling.scale(8)),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Scaling.scalePadding(16),
                                    vertical: Scaling.scalePadding(8),
                                  ),
                                ),
                                child: Semantics(
                                  label: AppLocalizations.of(context)!.editTransaction,
                                  child: Text(
                                    AppLocalizations.of(context)!.editTransaction,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Scaling.scaleFont(14),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: Scaling.scalePadding(8)),
                              ElevatedButton(
                                onPressed: () async {
                                  final confirmDelete = await _confirmDeleteTransaction(transaction.id!);
                                  if (confirmDelete) {
                                    await _deleteTransaction(transaction.id!);
                                    setState(() => _expandedIndices.remove(index));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Scaling.scale(8)),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Scaling.scalePadding(16),
                                    vertical: Scaling.scalePadding(8),
                                  ),
                                ),
                                child: Semantics(
                                  label: AppLocalizations.of(context)!.delete,
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Scaling.scaleFont(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: AppTextStyles.label(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              color: valueColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomCalendarDialog extends StatefulWidget {
  @override
  __CustomCalendarDialogState createState() => __CustomCalendarDialogState();
}

class __CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  @override
  Widget build(BuildContext context) {
    Scaling.init(context);
    final localizations = AppLocalizations.of(context)!;
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final calendarDate = transactionProvider.calendarDate;
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
                  onPressed: () {
                    transactionProvider.shiftCalendarMonth(-1);
                  },
                ),
                Text(
                  '${localizations.getShortMonthName(calendarDate.month)}, ${calendarDate.year}',
                  style: AppTextStyles.subheading(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: Scaling.scaleIcon(24),
                  ),
                  onPressed: () {
                    final now = DateTime.now();
                    final nextMonth = DateTime(calendarDate.year, calendarDate.month + 1, 1);
                    if (nextMonth.isBefore(now) || (nextMonth.month == now.month && nextMonth.year == now.year)) {
                      transactionProvider.shiftCalendarMonth(1);
                    }
                  },
                ),
              ],
            ),
            _buildCalendar(context),
            SizedBox(height: Scaling.scalePadding(16)),
            DropdownButton<String>(
              value: transactionProvider.dateFilter,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'Daily',
                  child: Text(localizations.daily, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: 'Weekly',
                  child: Text(localizations.weekly, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: 'Monthly',
                  child: Text(localizations.monthly, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: '3 Months',
                  child: Text(localizations.last3Months, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: '6 Months',
                  child: Text(localizations.last6Months, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: 'Yearly',
                  child: Text(localizations.yearly, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
                DropdownMenuItem(
                  value: 'Custom',
                  child: Text(localizations.custom, style: TextStyle(fontSize: Scaling.scaleFont(14))),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  transactionProvider.updateFilters(dateFilter: value);
                }
              },
              style: AppTextStyles.body(context),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              iconSize: Scaling.scaleIcon(24),
              borderRadius: BorderRadius.circular(Scaling.scale(8)),
              menuMaxHeight: Scaling.scale(200),
            ),
            SizedBox(height: Scaling.scalePadding(16)),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Scaling.scale(8)),
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
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final calendarDate = transactionProvider.calendarDate;
    final firstDayOfMonth = DateTime(calendarDate.year, calendarDate.month, 1);
    final lastDayOfMonth = DateTime(calendarDate.year, calendarDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday;

    final startingOffset = (firstDayWeekday - 1) % 7;
    final weekdays = [
      AppLocalizations.of(context)!.getShortWeekdayName(1), // Mon
      AppLocalizations.of(context)!.getShortWeekdayName(2), // Tue
      AppLocalizations.of(context)!.getShortWeekdayName(3), // Wed
      AppLocalizations.of(context)!.getShortWeekdayName(4), // Thu
      AppLocalizations.of(context)!.getShortWeekdayName(5), // Fri
      AppLocalizations.of(context)!.getShortWeekdayName(6), // Sat
      AppLocalizations.of(context)!.getShortWeekdayName(7), // Sun
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekdays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Scaling.scaleFont(14),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: Scaling.scalePadding(8)),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          childAspectRatio: 1,
          children: List.generate(startingOffset + daysInMonth, (index) {
            if (index < startingOffset) {
              return const SizedBox.shrink();
            }
            final day = index - startingOffset + 1;
            final date = DateTime(calendarDate.year, calendarDate.month, day);
            final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
            final isFuture = date.isAfter(today);
            final isSelected = (transactionProvider.dateFilter == 'Custom' &&
                transactionProvider.customStartDate != null &&
                transactionProvider.customEndDate != null &&
                date.isAfter(transactionProvider.customStartDate!.subtract(const Duration(days: 1))) &&
                date.isBefore(transactionProvider.customEndDate!.add(const Duration(days: 1)))) ||
                (transactionProvider.dateFilter == 'Daily' &&
                    transactionProvider.selectedStartDate != null &&
                    date.day == transactionProvider.selectedStartDate!.day &&
                    date.month == transactionProvider.selectedStartDate!.month &&
                    date.year == transactionProvider.selectedStartDate!.year);

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                transactionProvider.setDateFromCalendarTap(date);
              },
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

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}';
}