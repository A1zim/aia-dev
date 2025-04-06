import 'package:flutter/material.dart';
import 'package:aia_wallet/pages/HomeScreen.dart';
import 'package:aia_wallet/pages/ReportsScreen.dart';
import 'package:aia_wallet/pages/SettingsScreen.dart';
import 'package:aia_wallet/pages/TransactionHistoryScreen.dart';
import 'package:aia_wallet/services/LocalDataService.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/utils/scaling.dart'; // Import Scaling utility

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

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
    Scaling.init(context); // Initialize scaling

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: Scaling.scale(10),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontSize: Scaling.scaleFont(12),
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: Scaling.scaleFont(12),
            fontWeight: FontWeight.normal,
            color: unselectedColor,
          ),
          selectedItemColor: themeColor,
          unselectedItemColor: unselectedColor,
          items: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: AppLocalizations.of(context)?.home ?? 'Home',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: AppLocalizations.of(context)?.history ?? 'History',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.bar_chart,
              selectedIcon: Icons.bar_chart,
              label: AppLocalizations.of(context)?.reports ?? 'Reports',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: AppLocalizations.of(context)?.settingsTitle ?? 'Settings',
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
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    final themeColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(Scaling.scalePadding(8)),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(Scaling.scale(12)),
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
            color: isSelected ? themeColor : unselectedColor,
            size: Scaling.scaleIcon(28),
          ),
        ),
      ),
      label: label,
    );
  }
}