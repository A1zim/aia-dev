import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';
import 'package:personal_finance/localization/app_localizations.dart'; // Импорт локализации

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  bool _isLogin = true; // Switch between login and registration
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Handle login/registration
  Future<void> _handleAuth() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          // Login
          await _apiService.login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          // Registration
          await _apiService.register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );
          // Note: The register method already logs the user in, so no need to call login again
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.registeredSuccessfully,
                  style: AppTextStyles.body(context),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: AppTextStyles.body(context),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context); // Получаем локализацию здесь
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightAccent, AppColors.lightSurface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Header with Icon and Theme Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.account_circle,
                              size: 80,
                              color: AppColors.lightAccent, // Kept as lightAccent for visibility
                            ),
                            IconButton(
                              icon: Icon(
                                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                size: 28,
                              ),
                              onPressed: () {
                                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLogin ? localizations.welcomeBack : localizations.createAccount,
                          style: AppTextStyles.heading(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: localizations.username,
                            labelStyle: AppTextStyles.body(context).copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground.withOpacity(0.3)
                                : Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              ),
                            ),
                          ),
                          style: AppTextStyles.body(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterUsername;
                            }
                            if (value.length < 3) {
                              return localizations.usernameMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: localizations.password,
                            labelStyle: AppTextStyles.body(context).copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.lock, // Исправлено: Icons.lockphysics → Icons.lock
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground.withOpacity(0.3)
                                : Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              ),
                            ),
                          ),
                          style: AppTextStyles.body(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterPassword;
                            }
                            if (value.length < 6) {
                              return localizations.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (!_isLogin)
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelText: localizations.emailOptional,
                              labelStyle: AppTextStyles.body(context).copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkBackground.withOpacity(0.3)
                                  : Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                ),
                              ),
                            ),
                            style: AppTextStyles.body(context),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !value.contains('@')) {
                                return localizations.pleaseEnterValidEmail;
                              }
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor:
                                  isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              foregroundColor: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? localizations.login : localizations.register,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _usernameController.clear();
                              _passwordController.clear();
                              _emailController.clear();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? localizations.noAccountRegister
                                : localizations.haveAccountLogin,
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}