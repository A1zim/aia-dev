import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/currency_api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/widgets/drawer.dart';
import 'package:aia_wallet/widgets/summary_card.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  late TextEditingController _nicknameController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController; // For clear data confirmation
  String? _username;
  String? _email;
  String? _nickname;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  bool _isLoading = true;
  bool _showEmailHint = false;
  final Set<int> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController(); // Initialize controller for clear data
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchUserData();
    await _fetchSummaryData();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await _apiService.getUserData();
      setState(() {
        _username = userData['username'] ?? 'Unknown';
        _email = userData['email'] ?? 'user@example.com';
        _nickname = userData['nickname'] ?? '';
        _nicknameController.text = _nickname!;
      });
    } catch (e) {
      setState(() {
        _username = 'Unknown';
        _email = 'user@example.com';
        _nickname = '';
        _nicknameController.text = '';
      });
    }
  }

  Future<void> _fetchSummaryData() async {
    try {
      final summary = await _apiService.getFinancialSummary();
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final currentCurrency = currencyProvider.currency;

      final totalIncomeInKGS = summary['total_income']?.toDouble() ?? 0.0;
      final totalExpensesInKGS = summary['total_expense']?.toDouble() ?? 0.0;

      setState(() {
        _totalIncome = _convertAmount(totalIncomeInKGS, null, null, currentCurrency);
        _totalExpenses = _convertAmount(totalExpensesInKGS, null, null, currentCurrency);
        _balance = _totalIncome - _totalExpenses;
      });
    } catch (e) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.summaryLoadFailed(e.toString()),
        isError: true,
      );
    }
  }

  double _convertAmount(double amountInKGS, double? originalAmount, String? originalCurrency, String targetCurrency) {
    if (originalAmount != null && originalCurrency != null && originalCurrency == targetCurrency) {
      return originalAmount;
    }
    try {
      final rate = _currencyApiService.getConversionRate('KGS', targetCurrency);
      return amountInKGS * rate;
    } catch (e) {
      print('Error converting amount: $e');
      return amountInKGS;
    }
  }

  Future<void> _updateNickname() async {
    try {
      setState(() => _isLoading = true);
      await _apiService.updateUserProfile(nickname: _nicknameController.text);
      setState(() {
        _nickname = _nicknameController.text;
        _expandedCards.remove(0);
        _isLoading = false;
      });
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.nicknameUpdated,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.nicknameUpdateFailed(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      await _apiService.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      Navigator.pop(context);
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.passwordChanged,
      );
    } catch (e) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.passwordChangeFailed(e.toString()),
        isError: true,
      );
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(AppLocalizations.of(context)!.changePassword, style: AppTextStyles.subheading(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: AppLocalizations.of(context)!.oldPassword,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: AppLocalizations.of(context)!.newPassword,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel, style: AppTextStyles.body(context)),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text(AppLocalizations.of(context)!.confirm, style: AppTextStyles.body(context)),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            AppLocalizations.of(context)!.clearData,
            style: AppTextStyles.subheading(context),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.clearDataConfirm,
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: AppLocalizations.of(context)!.enterPassword,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _confirmPasswordController.clear();
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel, style: AppTextStyles.body(context)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.clearData(_confirmPasswordController.text);
                  _confirmPasswordController.clear();
                  Navigator.pop(context);
                  setState(() {
                    _totalIncome = 0.0;
                    _totalExpenses = 0.0;
                    _balance = 0.0;
                    _expandedCards.remove(2); // Collapse the card
                  });
                  NotificationService.showNotification(
                    context,
                    message: AppLocalizations.of(context)!.dataCleared,
                  );
                } catch (e) {
                  NotificationService.showNotification(
                    context,
                    message: AppLocalizations.of(context)!.clearDataFailed,
                    isError: true,
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.confirm, style: AppTextStyles.body(context)),
            ),
          ],
        );
      },
    );
  }

  String _truncateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final localPart = parts[0];
    final domainPart = parts[1];

    const maxLocalLength = 7;
    if (localPart.length <= maxLocalLength) {
      return email;
    }

    return '${localPart.substring(0, maxLocalLength)}...@$domainPart';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile, style: AppTextStyles.heading(context)),
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
      drawer: CustomDrawer(currentRoute: '/profile', parentContext: context),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildNicknameCard(),
            const SizedBox(height: 12),
            _buildUsernameEmailCard(),
            const SizedBox(height: 12),
            _buildBalanceCard(currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildNicknameCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedCards.contains(0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCards.remove(0);
            } else {
              _expandedCards.add(0);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.nickname}: ${_nickname!.isEmpty ? AppLocalizations.of(context)!.notSet : _nickname}',
                    style: AppTextStyles.subheading(context),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isExpanded ? null : 0,
              child: isExpanded
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nicknameController,
                      decoration: AppInputStyles.textField(context).copyWith(
                        labelText: AppLocalizations.of(context)!.enterNewNickname,
                      ),
                      maxLength: 18,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _updateNickname,
                          child: Text(AppLocalizations.of(context)!.save),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameEmailCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedCards.contains(1);
    final truncatedEmail = _truncateEmail(_email!);
    final shouldShowHint = _email!.length > 18;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCards.remove(1);
            } else {
              _expandedCards.add(1);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.username}: \n$_username',
                        style: AppTextStyles.subheading(context),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.email}: ',
                            style: AppTextStyles.subheading(context),
                          ),
                          shouldShowHint
                              ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showEmailHint = true;
                                  });
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() {
                                        _showEmailHint = false;
                                      });
                                    }
                                  });
                                },
                                child: Text(
                                  truncatedEmail,
                                  style: AppTextStyles.subheading(context),
                                ),
                              ),
                              if (_showEmailHint)
                                Positioned(
                                  top: -30,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _email!,
                                      style: AppTextStyles.body(context),
                                    ),
                                  ),
                                ),
                            ],
                          )
                              : Text(
                            truncatedEmail,
                            style: AppTextStyles.subheading(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isExpanded ? null : 0,
              child: isExpanded
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _showChangePasswordDialog,
                      child: Text(
                        AppLocalizations.of(context)!.changePassword,
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedCards.contains(2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCards.remove(2);
            } else {
              _expandedCards.add(2);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryCard(
              title: AppLocalizations.of(context)!.balance,
              amount: _balance.toStringAsFixed(2),
              currencySymbol: currencySymbol,
              color: Colors.blue,
              icon: Icons.account_balance_wallet,
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isExpanded ? null : 0,
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface, // Ensure consistent background
              child: isExpanded
                  ? Padding(
                padding: const EdgeInsets.only(top: 8.0), // Reduced padding for closer spacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SummaryCard(
                      title: AppLocalizations.of(context)!.income,
                      amount: _totalIncome.toStringAsFixed(2),
                      currencySymbol: currencySymbol,
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: 8), // Same spacing between all cards
                    SummaryCard(
                      title: AppLocalizations.of(context)!.expenses,
                      amount: _totalExpenses.toStringAsFixed(2),
                      currencySymbol: currencySymbol,
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(height: 8), // Spacing before the button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: _showClearDataDialog,
                        style: AppButtonStyles.elevatedButton(context).copyWith(
                          backgroundColor: WidgetStateProperty.all(Colors.red),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.clear,
                          style: AppTextStyles.body(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}