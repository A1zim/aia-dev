import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';

class CustomDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomDrawer({super.key, required this.currentRoute});

  Future<Map<String, String>> _fetchUserData() async {
    final ApiService apiService = ApiService();
    try {
      final userData = await apiService.getUserData();
      return {
        'nickname': userData['nickname'] ?? 'User',
        'email': userData['email'] ?? 'user@example.com',
        'username': userData['username'] ?? 'Unknown', // Add username
      };
    } catch (e) {
      return {
        'nickname': 'User',
        'email': 'user@example.com',
        'username': 'Unknown',
      };
    }
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

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: FutureBuilder<Map<String, String>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          final nickname = snapshot.data?['nickname'] ?? 'User';
          final email = snapshot.data?['email'] ?? 'user@example.com';
          final username = snapshot.data?['username'] ?? 'Unknown';

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
                        Icon(
                          Icons.account_circle,
                          size: 50,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
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
                      'Nickname: $nickname',
                      style: AppTextStyles.subheading(context),
                    ),
                    Text(
                      'Username: $username',
                      style: AppTextStyles.body(context).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      'Email: $email',
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
                selected: currentRoute == '/main',
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  if (currentRoute != '/main') {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/main',
                          (route) => false, // Remove all previous routes
                    );
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
                selected: currentRoute == '/profile',
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  if (currentRoute != '/profile') {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/profile',
                          (route) => false, // Remove all previous routes
                    );
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
                selected: currentRoute == '/currency',
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  if (currentRoute != '/currency') {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/currency',
                          (route) => false, // Remove all previous routes
                    );
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
                  Navigator.pop(context); // Close the drawer
                  _showLogoutDialog(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}