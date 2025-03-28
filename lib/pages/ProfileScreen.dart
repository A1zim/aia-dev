import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/currency_api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:personal_finance/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/currency_provider.dart';

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
  String? _username;
  String? _email;
  String? _nickname;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  bool _isLoading = true;
  int? _expandedIndex; // For card expansion

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load summary: $e')),
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
        _expandedIndex = null; // Collapse after saving
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname updated successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update nickname: $e')),
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
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
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
          title: Text('Change Password', style: AppTextStyles.subheading(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: 'Old Password',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: 'New Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.body(context)),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Confirm', style: AppTextStyles.body(context)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = _currencyApiService.getCurrencySymbol(currencyProvider.currency);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.heading(context)),
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
    final isExpanded = _expandedIndex == 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : 0;
          });
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nickname: ${_nickname!.isEmpty ? "Not set" : _nickname}',
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
                        labelText: 'Enter new nickname',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _updateNickname,
                          child: const Text('Save'),
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
    final isExpanded = _expandedIndex == 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : 1;
          });
        },
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
                        'Username: $_username',
                        style: AppTextStyles.subheading(context),
                      ),
                      Text(
                        'Email: $_email',
                        style: AppTextStyles.body(context),
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
                        'Change Password',
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
    final isExpanded = _expandedIndex == 2;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : 2;
          });
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance: ${_balance.toStringAsFixed(2)} $currencySymbol',
                    style: AppTextStyles.subheading(context).copyWith(
                      color: _balance >= 0 ? Colors.green : Colors.red,
                    ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income: ${_totalIncome.toStringAsFixed(2)} $currencySymbol',
                      style: AppTextStyles.body(context).copyWith(
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expenses: ${_totalExpenses.toStringAsFixed(2)} $currencySymbol',
                      style: AppTextStyles.body(context).copyWith(
                        color: Colors.red,
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