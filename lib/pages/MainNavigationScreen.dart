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
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _screens[_selectedIndex],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF121214) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: AppLocalizations.of(context)!.home,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: AppLocalizations.of(context)!.history,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.bar_chart,
                    selectedIcon: Icons.bar_chart,
                    label: AppLocalizations.of(context)!.reports,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: AppLocalizations.of(context)!.settingsTitle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = isDark ? Colors.purpleAccent[100]! : Colors.blue; // Blue for light, Purple for dark
    final unselectedColor = isDark ? Colors.purpleAccent! : Colors.blue[200]!; // Lighter shades for unselected

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
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
                color: isSelected ? Colors.white : unselectedColor,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}