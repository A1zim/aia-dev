import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';

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
  late Animation<double> _rotateAnimation;
  static Map<String, String>? _userDataCache;
  bool _isLoading = false;
  bool _isDarkMode = false; // Track the current theme state for the icon

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize _isDarkMode based on the current theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
            (themeProvider.themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
      });
    });

    if (_userDataCache == null && !_isLoading) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final data = await _fetchUserData();
    if (mounted) {
      setState(() {
        _userDataCache = data;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _fetchUserData() async {
    final ApiService apiService = ApiService();
    try {
      final userData = await apiService.getUserData();
      return {
        'username': userData['username'] ?? 'Unknown',
        'email': userData['email'] ?? 'user@example.com',
        'nickname': userData['nickname'] ?? '',
      };
    } catch (e) {
      return {
        'username': 'Unknown',
        'email': 'user@example.com',
        'nickname': '',
      };
    }
  }

  String _truncateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final localPart = parts[0];
    final domainPart = parts[1];
    const maxLocalLength = 7;
    if (localPart.length <= maxLocalLength) return email;

    return '${localPart.substring(0, maxLocalLength)}...@$domainPart';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.logout,
            style: AppTextStyles.subheading(context),
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutConfirm,
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: AppTextStyles.body(context),
              ),
            ),
            TextButton(
              style: AppButtonStyles.textButton(context),
              onPressed: () async {
                final apiService = ApiService();
                await apiService.clearTokens();
                Navigator.pop(context);
                Navigator.pop(widget.parentContext);
                await Future.delayed(const Duration(milliseconds: 300));
                Navigator.pushNamedAndRemoveUntil(
                  widget.parentContext,
                  '/',
                      (route) => false,
                );
              },
              child: Text(
                AppLocalizations.of(context)!.confirmLogout,
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

  void _navigateWithoutClosingDrawer(String route) {
    Navigator.pushNamed(widget.parentContext, route);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final themeColor = isDark ? Colors.purpleAccent : Colors.blue;
    final unselectedColor = isDark ? Colors.purpleAccent[100]! : Colors.blue[200]!;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      backgroundColor: isDark ? Color(0xFF121214)  : Colors.white,
      child: _userDataCache == null && _isLoading
          ? _buildLoadingState(isDark, themeColor)
          : _buildDrawerContent(
        isDark: isDark,
        themeColor: themeColor,
        unselectedColor: unselectedColor,
        username: _userDataCache?['username'] ?? 'Unknown',
        email: _userDataCache?['email'] ?? 'user@example.com',
        nickname: _userDataCache?['nickname'] ?? '',
      ),
    );
  }

  Widget _buildDrawerContent({
    required bool isDark,
    required Color themeColor,
    required Color unselectedColor,
    required String username,
    required String email,
    required String nickname,
  }) {
    final displayName = nickname.isNotEmpty ? nickname : username;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.purple[900]!, Colors.purple[700]!]
                  : [Colors.blue[700]!, Colors.blue[500]!],
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
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _animationController.forward(from: 0); // Start rotation
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      // Update icon state halfway through the animation
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          setState(() {
                            _isDarkMode = !_isDarkMode;
                          });
                        }
                      });
                    },
                    child: RotationTransition(
                      turns: _rotateAnimation,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
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
                          _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          key: ValueKey(_isDarkMode),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                displayName,
                style: AppTextStyles.subheading(context).copyWith(color: Colors.white),
              ),
              Text(
                _truncateEmail(email),
                style: AppTextStyles.body(context).copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        _buildNavItem(
          icon: Icons.home,
          title: AppLocalizations.of(context)!.home,
          route: '/main',
          isSelected: widget.currentRoute == '/main',
          themeColor: themeColor,
          unselectedColor: unselectedColor,
        ),
        _buildNavItem(
          icon: Icons.person,
          title: AppLocalizations.of(context)!.profile,
          route: '/profile',
          isSelected: widget.currentRoute == '/profile',
          themeColor: themeColor,
          unselectedColor: unselectedColor,
        ),
        _buildNavItem(
          icon: Icons.monetization_on,
          title: AppLocalizations.of(context)!.currency,
          route: '/currency',
          isSelected: widget.currentRoute == '/currency',
          themeColor: themeColor,
          unselectedColor: unselectedColor,
        ),
        _buildNavItem(
          icon: Icons.logout,
          title: AppLocalizations.of(context)!.logout,
          route: null,
          isSelected: false,
          themeColor: themeColor,
          unselectedColor: unselectedColor,
          onTap: () => _showLogoutDialog(widget.parentContext),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark, Color themeColor) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.purple[900]!, Colors.purple[700]!]
                  : [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required Color themeColor,
    required Color unselectedColor,
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? (route != null ? () => _navigateWithoutClosingDrawer(route) : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
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
                icon,
                key: ValueKey(isSelected),
                color: isSelected ? Colors.white : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}