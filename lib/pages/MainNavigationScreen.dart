import 'package:flutter/material.dart';
import 'package:personal_finance/pages/HomeScreen.dart';
import 'package:personal_finance/pages/ReportsScreen.dart';
import 'package:personal_finance/pages/SettingsScreen.dart';
import 'package:personal_finance/pages/TransactionHistoryScreen.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart'; // Import the styles file

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const MainNavigationScreen({super.key, this.onThemeToggle});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        key: const ValueKey('HomeScreen'),
        onThemeToggle: widget.onThemeToggle,
      ),
      const TransactionHistoryScreen(key: ValueKey('TransactionHistoryScreen')),
      const ReportsScreen(key: ValueKey('ReportsScreen')),
      SettingsScreen(
        key: const ValueKey('SettingsScreen'),
        onThemeToggle: widget.onThemeToggle, // Pass the theme toggle callback
      ),
    ];
    _checkAuthentication();
  }

  // Check if the user is authenticated
  Future<void> _checkAuthentication() async {
    try {
      final token = await _apiService.getAccessToken();
      if (token == null) {
        _navigateToLogin();
      } else {
        // Optionally, make a test API call to verify the token
        await _apiService.getFinancialSummary();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.darkShadow
                  : AppColors.lightShadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? (isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: _selectedIndex == 0
                        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? (isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_outlined,
                    color: _selectedIndex == 1
                        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
                label: 'History',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? (isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_outlined,
                    color: _selectedIndex == 2
                        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? (isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: _selectedIndex == 3
                        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent.withOpacity(0.2)
                        : AppColors.lightAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}