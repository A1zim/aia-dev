import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/services/api_service.dart';
import 'package:personal_finance/services/notification_service.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/providers/theme_provider.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isVerificationStep = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

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
            NotificationService.showNotification(
              context,
              message: "Login successful! 🎉",
            );
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          await _apiService.register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            email: _emailController.text.trim(),
          );
          if (mounted) {
            setState(() {
              _isVerificationStep = true;
              _isLoading = false;
            });
            NotificationService.showNotification(
              context,
              message: "A 6-digit code has been sent to your email. 📧",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          NotificationService.showNotification(
            context,
            message: errorMessage,
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String code = _codeControllers.map((controller) => controller.text).join();
        await _apiService.verifyEmail(
          _emailController.text.trim(),
          code,
        );
        await _apiService.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: "Email verified successfully! Logging you in... 🎉",
          );
          Navigator.pushReplacementNamed(context, '/main');
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          NotificationService.showNotification(
            context,
            message: errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NotificationService.showNotification(
        context,
        message: "Please enter a valid email! 📧",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(email);
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: "A 6-digit code has been sent to your email. Use it to log in! 📧",
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        NotificationService.showNotification(
          context,
          message: errorMessage,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text('Forgot Password', style: AppTextStyles.subheading(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email to receive a 6-digit code.',
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: AppInputStyles.textField(context).copyWith(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.body(context)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleForgotPassword();
              },
              child: Text('Send Code', style: AppTextStyles.body(context)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.account_circle,
                              size: 80,
                              color: AppColors.lightAccent,
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
                          _isVerificationStep
                              ? "Verify Your Email"
                              : _isLogin
                              ? "Welcome Back!"
                              : "Create Account",
                          style: AppTextStyles.heading(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_isVerificationStep) ...[
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
                          const SizedBox(height: 8),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  ),
                                ),
                              ),
                            ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelText: 'Email',
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
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        if (_isVerificationStep) ...[
                          Text(
                            'Enter the 6-digit code sent to ${_emailController.text}',
                            style: AppTextStyles.body(context).copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: _codeControllers[index],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                    counterText: '',
                                  ),
                                  style: AppTextStyles.body(context).copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    textBaseline: TextBaseline.alphabetic,
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  onChanged: (value) {
                                    if (value.length == 1 && index < 5) {
                                      FocusScope.of(context).nextFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      FocusScope.of(context).previousFocus();
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '';
                                    }
                                    if (!RegExp(r'^\d$').hasMatch(value)) {
                                      return '';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_isVerificationStep ? _handleVerification : _handleAuth),
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
                              _isVerificationStep
                                  ? "Verify"
                                  : _isLogin
                                  ? "Login"
                                  : "Register",
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
                        if (!_isVerificationStep)
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
                        if (_isVerificationStep)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isVerificationStep = false;
                                for (var controller in _codeControllers) {
                                  controller.clear();
                                }
                              });
                            },
                            child: Text(
                              "Back to Registration",
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