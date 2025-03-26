import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const SettingsScreen({super.key, this.onThemeToggle});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedCurrency = 'KGS'; // Changed default to KGS
  String _previousCurrency = 'KGS'; // Changed default to KGS
  bool _isFingerprintEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedCurrency = prefs.getString('currency') ?? 'KGS';
        _previousCurrency = _selectedCurrency;
        _isFingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If currency has changed, we need to convert transactions
      if (_previousCurrency != _selectedCurrency) {
        setState(() {
          _isLoading = true; // Show loading indicator
        });
        
        await _convertAllTransactions(_previousCurrency, _selectedCurrency);
        _previousCurrency = _selectedCurrency;
      }
      
      // Save the new settings
      await prefs.setString('currency', _selectedCurrency);
      await prefs.setBool('fingerprint_enabled', _isFingerprintEnabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _convertAllTransactions(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return;
    
    try {
      // Get the conversion rate
      final rate = await _apiService.getExchangeRate(fromCurrency, toCurrency);
      
      // Save the new preferred currency
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', toCurrency);
      
      // For UI feedback only
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency converted: 1 $fromCurrency = $rate $toCurrency'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Note: We're not modifying the actual transaction amounts in the database
      // The conversion will happen on-the-fly when displaying the amounts
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert currency: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // Revert to previous currency if conversion fails
      setState(() {
        _selectedCurrency = _previousCurrency;
      });
    }
  }

  void _selectCurrency(String? value) {
    if (value == null) return;
    
    setState(() {
      _selectedCurrency = value;
    });
    _saveSettings();
  }

  void _toggleFingerprint(bool value) {
    setState(() {
      _isFingerprintEnabled = value;
    });
    _saveSettings();
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
      body: Stack(
        children: [
          Container(
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
                        DropdownMenuItem(value: 'KGS', child: Text('KGS - Kyrgyz Som')),
                        DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP - British Pound')),
                        DropdownMenuItem(value: 'JPY', child: Text('JPY - Japanese Yen')),
                        DropdownMenuItem(value: 'CAD', child: Text('CAD - Canadian Dollar')),
                        DropdownMenuItem(value: 'AUD', child: Text('AUD - Australian Dollar')),
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}