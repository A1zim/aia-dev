import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/services/notification_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'dart:ui';

class CircleClipper extends CustomClipper<Path> {
  CircleClipper({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircleClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isVerificationStep = false;

  // For theme switch animation
  bool _isThemeSwitching = false;
  bool _fadeInContent = false;
  Offset _buttonPosition = Offset.zero;
  double _revealRadius = 0.0;
  double _overlayOpacity = 0.0;
  late AnimationController _animationController;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  String _currentLogoPath = 'assets/images/aia_logo_w.png';
  bool _isDarkMode = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers =
  List.generate(6, (_) => TextEditingController());
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final GlobalKey _themeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _radiusAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    )..addListener(() {
      setState(() {
        _revealRadius = _radiusAnimation.value * _getMaxRadius();
      });
    });

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    )..addListener(() {
      setState(() {
        _overlayOpacity = _opacityAnimation.value;
      });
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isThemeSwitching = false;
          _fadeInContent = true;
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          _currentLogoPath = themeProvider.getLogoPath(context);
          _isDarkMode = Theme.of(context).brightness == Brightness.dark;
        });
      }
    });

    _fadeInContent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _currentLogoPath = themeProvider.getLogoPath(context);
        _isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  double _getMaxRadius() {
    final size = MediaQuery.of(context).size;
    return size.width * 1.5;
  }

  void _startThemeSwitchAnimation() {
    final RenderBox renderBox =
    _themeButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() {
      _isThemeSwitching = true;
      _fadeInContent = false;
      _buttonPosition = position + Offset(size.width / 2, size.height / 2);
      _revealRadius = 0;
      _overlayOpacity = 0;
      _animationController.forward(from: 0);
    });
  }

  Future<void> _handleAuth() async {
    print('Username: "${_usernameController.text.trim()}"');
    print('Password: "${_passwordController.text.trim()}"');
    final formKey = _isLogin ? _loginFormKey : _registerFormKey;
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          print('Attempting to login...');
          await _apiService.login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
          print('Login successful');
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: AppLocalizations.of(context)!.loginSuccessful,
            );
            print('Navigating to /main');
            _usernameController.clear();
            _passwordController.clear();
            _emailController.clear();
            try {
              await Navigator.pushReplacementNamed(context, '/main');
            } catch (e) {
              print('Navigation error: $e');
              NotificationService.showNotification(
                context,
                message: 'Navigation failed: $e',
                isError: true,
              );
            }
          }
        } else {
          print('Attempting to register...');
          await _apiService.register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            email: _emailController.text.trim(),
          );
          print('Registration successful');
          if (mounted) {
            setState(() {
              _isVerificationStep = true;
              _isLoading = false;
            });
            NotificationService.showNotification(
              context,
              message: AppLocalizations.of(context)!.codeSentToEmail,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          print('Error during auth: $e');
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          NotificationService.showNotification(
            context,
            message: errorMessage,
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      print('Form validation failed');
    }
  }

  Future<void> _handleVerification() async {
    if (_verificationFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Verifying email...');
        String code = _codeControllers.map((controller) => controller.text).join();
        await _apiService.verifyEmail(
          _emailController.text.trim(),
          code,
        );
        print('Email verified, logging in...');
        await _apiService.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
        print('Login after verification successful');
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: AppLocalizations.of(context)!.emailVerified,
          );
          print('Navigating to /main');
          _usernameController.clear();
          _passwordController.clear();
          _emailController.clear();
          for (var controller in _codeControllers) {
            controller.clear();
          }
          try {
            await Navigator.pushReplacementNamed(context, '/main');
          } catch (e) {
            print('Navigation error: $e');
            NotificationService.showNotification(
              context,
              message: 'Navigation failed: $e',
              isError: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          print('Error during verification: $e');
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
    } else {
      print('Verification form validation failed');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NotificationService.showNotification(
        context,
        message: AppLocalizations.of(context)!.emailInvalid,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Sending forgot password code to $email...');
      await _apiService.forgotPassword(email);
      print('Forgot password code sent');
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: AppLocalizations.of(context)!.codeSentForLogin,
        );
        setState(() {
          _isLoading = false;
          _emailController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error during forgot password: $e');
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
        final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.grey[300],
          title: Text(
            AppLocalizations.of(context)!.forgotPasswordTitle,
            style: AppTextStyles.subheading(context).copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.forgotPasswordPrompt,
                style: AppTextStyles.body(context).copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: AppLocalizations.of(context)!.email,
                  labelStyle: const TextStyle(
                    color: Colors.blue,
                  ),
                  prefixIcon: const Icon(
                    Icons.email,
                    color: Colors.blue,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                    ),
                  ),
                  errorStyle: TextStyle(
                    color: isDark ? Colors.redAccent : Colors.red,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.emailRequired;
                  }
                  if (!value.contains('@')) {
                    return AppLocalizations.of(context)!.emailInvalid;
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  Navigator.pop(context);
                  _handleForgotPassword();
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleForgotPassword();
              },
              child: Text(
                AppLocalizations.of(context)!.sendCode,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];

    return Scaffold(
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isThemeSwitching,
            child: AnimatedOpacity(
              opacity: _fadeInContent ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkTextSecondary.withOpacity(0.2)
                                    : Colors.grey[400]!,
                                width: 1,
                              ),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                _currentLogoPath,
                                                height: 80,
                                                width: 80,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(width: 4),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'AIA',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: _isDarkMode
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.lightTextPrimary,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: 'Wallet',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.normal,
                                                        color: _isDarkMode
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.lightTextPrimary,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        key: _themeButtonKey,
                                        icon: Icon(
                                          isDark ? Icons.wb_sunny : Icons.nightlight_round,
                                          color: Colors.blue,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          _startThemeSwitchAnimation();
                                          themeProvider.toggleTheme();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20), // Keep larger spacing for major section
                                  if (!_isVerificationStep) ...[
                                    Text(
                                      AppLocalizations.of(context)!.welcome,
                                      style: AppTextStyles.heading(context).copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16), // Standardized to 16
                                    Text(
                                      _isLogin
                                          ? AppLocalizations.of(context)!.login
                                          : AppLocalizations.of(context)!.createAccount,
                                      style: AppTextStyles.heading(context).copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                  if (_isVerificationStep) ...[
                                    Text(
                                      AppLocalizations.of(context)!.verifyYourEmail,
                                      style: AppTextStyles.heading(context).copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20), // Keep larger spacing for major section
                                  if (!_isVerificationStep) ...[
                                    AnimatedCrossFade(
                                      firstChild: Form(
                                        key: _loginFormKey,
                                        child: _buildLoginForm(),
                                      ),
                                      secondChild: Form(
                                        key: _registerFormKey,
                                        child: _buildRegisterForm(),
                                      ),
                                      crossFadeState: _isLogin
                                          ? CrossFadeState.showFirst
                                          : CrossFadeState.showSecond,
                                      duration: const Duration(milliseconds: 300),
                                      firstCurve: Curves.easeInOut,
                                      secondCurve: Curves.easeInOut,
                                      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                                        return Stack(
                                          children: [
                                            Positioned(
                                              key: bottomChildKey,
                                              child: bottomChild,
                                            ),
                                            Positioned(
                                              key: topChildKey,
                                              child: topChild,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_isVerificationStep) ...[
                                    Text(
                                      AppLocalizations.of(context)!
                                          .enterCodePrompt(_emailController.text),
                                      style: AppTextStyles.body(context).copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Form(
                                      key: _verificationFormKey,
                                      child: Row(
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
                                                fillColor: isDark ? Colors.grey[800] : cardColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                counterText: '',
                                                errorStyle: TextStyle(
                                                  color: isDark ? Colors.redAccent : Colors.red,
                                                ),
                                              ),
                                              style: AppTextStyles.body(context).copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                textBaseline: TextBaseline.alphabetic,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.lightTextPrimary,
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
                                            ? AppLocalizations.of(context)!.verify
                                            : _isLogin
                                            ? AppLocalizations.of(context)!.login
                                            : AppLocalizations.of(context)!.register,
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
                                            ? AppLocalizations.of(context)!.dontHaveAccount
                                            : AppLocalizations.of(context)!.alreadyHaveAccount,
                                        style: const TextStyle(
                                          color: Colors.blue,
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
                                        AppLocalizations.of(context)!.backToRegistration,
                                        style: const TextStyle(
                                          color: Colors.blue,
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
              ),
            ),
          ),
          if (_isThemeSwitching)
            Opacity(
              opacity: _overlayOpacity,
              child: ClipPath(
                clipper: CircleClipper(
                  center: _buttonPosition,
                  radius: _revealRadius,
                ),
                child: Container(
                  color: !isDark ? Colors.grey[300] : AppColors.darkBackground,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];

    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.username,
            labelStyle: const TextStyle(
              color: Colors.blue,
            ),
            prefixIcon: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            errorStyle: TextStyle(
              color: isDark ? Colors.redAccent : Colors.red,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.usernameRequired;
            }
            if (value.length < 3) {
              return AppLocalizations.of(context)!.usernameTooShort;
            }
            return null;
          },
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.password,
            labelStyle: const TextStyle(
              color: Colors.blue,
            ),
            prefixIcon: const Icon(
              Icons.lock,
              color: Colors.blue,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            errorStyle: TextStyle(
              color: isDark ? Colors.redAccent : Colors.red,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.passwordRequired;
            }
            if (value.length < 6) {
              return AppLocalizations.of(context)!.passwordTooShort;
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleAuth(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16), // Standardized to 16
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(
              AppLocalizations.of(context)!.forgotPassword,
              style: const TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];

    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.username,
            labelStyle: const TextStyle(
              color: Colors.blue,
            ),
            prefixIcon: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            errorStyle: TextStyle(
              color: isDark ? Colors.redAccent : Colors.red,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.usernameRequired;
            }
            if (value.length < 3) {
              return AppLocalizations.of(context)!.usernameTooShort;
            }
            return null;
          },
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.password,
            labelStyle: const TextStyle(
              color: Colors.blue,
            ),
            prefixIcon: const Icon(
              Icons.lock,
              color: Colors.blue,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            errorStyle: TextStyle(
              color: isDark ? Colors.redAccent : Colors.red,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.passwordRequired;
            }
            if (value.length < 6) {
              return AppLocalizations.of(context)!.passwordTooShort;
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16), // Standardized to 16
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.email,
            labelStyle: const TextStyle(
              color: Colors.blue,
            ),
            prefixIcon: const Icon(
              Icons.email,
              color: Colors.blue,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            errorStyle: TextStyle(
              color: isDark ? Colors.redAccent : Colors.red,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.emailRequired;
            }
            if (!value.contains('@')) {
              return AppLocalizations.of(context)!.emailInvalid;
            }
            return null;
          },
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleAuth(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}