import 'package:flutter/material.dart';
import 'package:aia_wallet/pages/HomeScreen.dart';
import 'package:aia_wallet/pages/ReportsScreen.dart';
import 'package:aia_wallet/pages/SettingsScreen.dart';
import 'package:aia_wallet/pages/TransactionHistoryScreen.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

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
      const HomeScreen(key: ValueKey('HomeScreen')),
      const TransactionHistoryScreen(key: ValueKey('TransactionHistoryScreen')),
      const ReportsScreen(key: ValueKey('ReportsScreen')),
      const SettingsScreen(key: ValueKey('SettingsScreen')),
    ];
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final token = await _apiService.getAccessToken();
      if (token == null) {
        _navigateToLogin();
      } else {
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
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
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
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface, // Theme-adaptive background
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2), // Shadow above the navigation bar
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensures all items are visible
          backgroundColor: Colors.transparent, // Make the BottomNavigationBar background transparent to show the Container's color
          elevation: 0, // No additional elevation (shadow is handled by the Container)
          showSelectedLabels: false, // Hide selected labels
          showUnselectedLabels: false, // Hide unselected labels
          items: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.bar_chart,
              selectedIcon: Icons.bar_chart,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    final themeColor = isDark ? AppColors.darkAccent : AppColors.lightAccent; // Purple for dark, blue for light
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary; // Theme-adaptive unselected color

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(8), // Add padding for a nicer look
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.2) : Colors.transparent, // Subtle background for selected item
          borderRadius: BorderRadius.circular(12), // Rounded highlight
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isSelected ? selectedIcon : icon,
            key: ValueKey(isSelected),
            color: isSelected ? themeColor : unselectedColor, // Theme-adaptive colors
            size: 28, // Slightly larger icons for a nicer look
          ),
        ),
      ),
      label: '', // Empty label since we don't want text
    );
  }
}