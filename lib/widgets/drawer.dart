import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';

class CustomDrawer extends StatefulWidget {
  final String currentRoute;
  final BuildContext parentContext;

  const CustomDrawer({
    super.key,
    required this.currentRoute,
    required this.parentContext,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchUserData() async {
    final ApiService apiService = ApiService();
    try {
      final userData = await apiService.getUserData();
      return {
        'username': userData['username'] ?? 'Unknown',
        'email': userData['email'] ?? 'user@example.com',
        'nickname': userData['nickname'] ?? '', // Fetch nickname
      };
    } catch (e) {
      return {
        'username': 'Unknown',
        'email': 'user@example.com',
        'nickname': '',
      };
    }
  }

  // Helper function to truncate email to 18 characters
  String _truncateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email; // Invalid email format

    final localPart = parts[0];
    final domainPart = parts[1];

    // Show first 7 characters of local part, then "...", then domain
    const maxLocalLength = 7;
    if (localPart.length <= maxLocalLength) {
      return email; // If local part is short, return as is
    }

    return '${localPart.substring(0, maxLocalLength)}...@$domainPart';
  }

  void _showLogoutDialog(BuildContext context) {
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
                final apiService = ApiService();
                await apiService.clearTokens();
                Navigator.pop(context); // Close the dialog
                await Future.delayed(const Duration(milliseconds: 300));
                Navigator.pushNamedAndRemoveUntil(
                  widget.parentContext,
                  '/',
                      (route) => false,
                );
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

  void _navigateAfterDrawerClose(String route) {
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(
      widget.parentContext,
      route,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<Map<String, String>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.darkPrimary, AppColors.darkSecondary]
                            : [AppColors.lightPrimary, AppColors.lightSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.darkPrimary, AppColors.darkSecondary]
                            : [AppColors.lightPrimary, AppColors.lightSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Error loading user data',
                        style: AppTextStyles.body(context).copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final username = snapshot.data?['username'] ?? 'Unknown';
            final email = snapshot.data?['email'] ?? 'user@example.com';
            final nickname = snapshot.data?['nickname'] ?? '';

            // Use nickname if available, otherwise fall back to username
            final displayName = nickname.isNotEmpty ? nickname : username;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkPrimary, AppColors.darkSecondary]
                          : [AppColors.lightPrimary, AppColors.lightSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 50), // Placeholder to maintain layout
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.wb_sunny : Icons.nightlight_round,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              size: 28,
                            ),
                            onPressed: () {
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleTheme();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: AppTextStyles.subheading(context),
                      ),
                      Text(
                        _truncateEmail(email),
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.home,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  title: Text(
                    'Home',
                    style: AppTextStyles.body(context),
                  ),
                  selected: widget.currentRoute == '/main',
                  onTap: () {
                    if (widget.currentRoute != '/main') {
                      _navigateAfterDrawerClose('/main');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  title: Text(
                    'Profile',
                    style: AppTextStyles.body(context),
                  ),
                  selected: widget.currentRoute == '/profile',
                  onTap: () {
                    if (widget.currentRoute != '/profile') {
                      _navigateAfterDrawerClose('/profile');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.monetization_on,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  title: Text(
                    'Currency',
                    style: AppTextStyles.body(context),
                  ),
                  selected: widget.currentRoute == '/currency',
                  onTap: () {
                    if (widget.currentRoute != '/currency') {
                      _navigateAfterDrawerClose('/currency');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                  title: Text(
                    'Logout',
                    style: AppTextStyles.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(widget.parentContext);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}