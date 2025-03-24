import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isDarkMode = false;
  String _selectedCurrency = 'USD';
  bool _isFingerprintEnabled = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

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
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _apiService.clearTokens();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile.adaptive(
                title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                subtitle: Text(_isDarkMode ? 'Enabled' : 'Disabled'),
                value: _isDarkMode,
                onChanged: (value) => _toggleTheme(),
                secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Currency Selection
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.deepPurple),
              title: const Text('Select Currency', style: TextStyle(fontSize: 16)),
              subtitle: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                onChanged: _selectCurrency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                  DropdownMenuItem(value: 'INR', child: Text('INR - Indian Rupee')),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Fingerprint Authentication
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile.adaptive(
                title: const Text('Enable Fingerprint', style: TextStyle(fontSize: 16)),
                subtitle: Text(_isFingerprintEnabled ? 'Enabled' : 'Disabled'),
                value: _isFingerprintEnabled,
                onChanged: _toggleFingerprint,
                secondary: const Icon(Icons.fingerprint, color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Logout Option
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.deepPurple),
              title: const Text('Logout', style: TextStyle(fontSize: 16)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}