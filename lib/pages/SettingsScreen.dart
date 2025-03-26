import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart'; // Import the styles file

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const SettingsScreen({super.key, this.onThemeToggle});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedCurrency = 'USD';
  bool _isFingerprintEnabled = false;

  void _selectCurrency(String? value) {
    setState(() {
      _selectedCurrency = value!;
    });
  }

  void _toggleFingerprint(bool value) {
    setState(() {
      _isFingerprintEnabled = value;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppTextStyles.subheading(context),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.body(context),
              ),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                await _apiService.clearTokens();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text(
                'Logout',
                style: AppTextStyles.body(context).copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: SwitchListTile.adaptive(
                  title: Text(
                    'Dark Mode',
                    style: AppTextStyles.body(context).copyWith(fontSize: 16),
                  ),
                  subtitle: Text(
                    isDark ? 'Enabled' : 'Disabled',
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    widget.onThemeToggle?.call();
                  },
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Currency Selection
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Select Currency',
                  style: AppTextStyles.body(context).copyWith(fontSize: 16),
                ),
                subtitle: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  onChanged: _selectCurrency,
                  decoration: AppInputStyles.dropdown(context).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                    DropdownMenuItem(value: 'INR', child: Text('INR - Indian Rupee')),
                  ],
                  itemHeight: 50,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Fingerprint Authentication
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: SwitchListTile.adaptive(
                  title: Text(
                    'Enable Fingerprint',
                    style: AppTextStyles.body(context).copyWith(fontSize: 16),
                  ),
                  subtitle: Text(
                    _isFingerprintEnabled ? 'Enabled' : 'Disabled',
                    style: AppTextStyles.body(context).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: _isFingerprintEnabled,
                  onChanged: _toggleFingerprint,
                  secondary: Icon(
                    Icons.fingerprint,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),

              // Logout Option
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Logout',
                  style: AppTextStyles.body(context).copyWith(fontSize: 16),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}