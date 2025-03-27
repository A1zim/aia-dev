import 'package:flutter/material.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';

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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await _apiService.login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          await _apiService.register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            email: _emailController.text.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Registration successful! Please verify your email.",
                  style: AppTextStyles.body(context),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            setState(() {
              _isLogin = true; // Switch to login mode after registration
              _usernameController.clear();
              _passwordController.clear();
              _emailController.clear();
            });
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          if (errorMessage == "Email not verified. Please verify your email before logging in.") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Please verify your email before logging in.",
                  style: AppTextStyles.body(context),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else {
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
                                Provider.of<ThemeProvider>(context, listen: false)
                                    .toggleTheme();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLogin ? "Welcome Back!" : "Create Account",
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
                            labelText: 'Username',
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
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
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
                            labelText: 'Password',
                            labelStyle: AppTextStyles.body(context).copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
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
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (!_isLogin)
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              labelText: 'Email',
                              labelStyle: AppTextStyles.body(context).copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              prefixIcon: Icon(Icons.email, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                              filled: true,
                              fillColor: isDark ? AppColors.darkBackground.withOpacity(0.3) : Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                              ),
                            ),
                            style: AppTextStyles.body(context),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email'; // Делаем email обязательным
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
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
                              _isLogin ? "Login" : "Register",
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
                                ? "Don't have an account? Register"
                                : "Already have an account? Login",
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