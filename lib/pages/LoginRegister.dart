import 'package:flutter/material.dart';
import 'package:aia_wallet/services/api_service.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'dart:ui';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isVerificationStep = false;
  bool _isFading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final GlobalKey _themeButtonKey = GlobalKey();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final GlobalKey _usernameFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();

  // Field-specific error messages
  String? _usernameError;
  String? _passwordError;
  String? _emailError;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  void _toggleTheme() {
    setState(() => _isFading = true);
    Future.delayed(const Duration(milliseconds: 150), () { // Faster transition: 300ms -> 150ms
      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      setState(() => _isFading = false);
    });
  }

  void _toggleLoginRegister() {
    setState(() {
      _isLogin = !_isLogin;
      _usernameError = null;
      _passwordError = null;
      _emailError = null;
      _verificationError = null;
    });
  }

  void _shakeField(GlobalKey key) {
    _shakeController.reset();
    _shakeController.forward();
    (key.currentState as _ShakeFieldState?)?.shake();
  }

  Future<void> _handleAuth() async {
    final formKey = _isLogin ? _loginFormKey : _registerFormKey;
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _emailError = null;
      _verificationError = null;
    });

    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await _apiService.login(_usernameController.text.trim(), _passwordController.text.trim());
          if (mounted) Navigator.pushReplacementNamed(context, '/main');
        } else {
          await _apiService.register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            email: _emailController.text.trim(),
          );
          if (mounted) setState(() {
            _isVerificationStep = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          if (errorMessage.contains('Username already exists')) {
            _shakeField(_usernameFieldKey);
            setState(() => _usernameError = 'Username is already taken');
          } else if (errorMessage.contains('Email already exists')) {
            _shakeField(_emailFieldKey);
            setState(() => _emailError = 'Email is already registered');
          } else if (errorMessage.contains('user_not_found')) {
            _shakeField(_usernameFieldKey);
            setState(() => _usernameError = 'User not found');
          } else if (errorMessage.contains('password_incorrect')) {
            _shakeField(_passwordFieldKey);
            setState(() => _passwordError = 'Incorrect password');
          } else {
            setState(() => _verificationError = errorMessage); // Fallback to verification error if no specific field
          }
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (_usernameController.text.isEmpty || _usernameController.text.length < 3) _shakeField(_usernameFieldKey);
      if (_passwordController.text.isEmpty || _passwordController.text.length < 6) _shakeField(_passwordFieldKey);
      if (!_isLogin && (_emailController.text.isEmpty || !_emailController.text.contains('@'))) _shakeField(_emailFieldKey);
    }
  }

  Future<void> _handleVerification() async {
    if (_verificationFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _verificationError = null;
      });
      try {
        String code = _codeControllers.map((controller) => controller.text).join();
        await _apiService.verifyEmail(_emailController.text.trim(), code);
        await _apiService.login(_usernameController.text.trim(), _passwordController.text.trim());
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          if (errorMessage.contains('Invalid verification code')) {
            setState(() => _verificationError = 'Invalid verification code');
            for (var controller in _codeControllers) {
              if (controller.text.isEmpty) {
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(const Duration(milliseconds: 100), () => FocusScope.of(context).requestFocus(FocusNode()));
                break;
              }
            }
          } else if (errorMessage.contains('expired')) {
            setState(() => _verificationError = 'Code has expired. Please register again.');
          } else {
            setState(() => _verificationError = errorMessage);
          }
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _verificationError = 'Please enter a valid 6-digit code');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _shakeField(_emailFieldKey);
      setState(() => _emailError = AppLocalizations.of(context)!.emailInvalid);
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });
    try {
      await _apiService.forgotPassword(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordSent), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorStr = e.toString().replaceFirst('Exception: ', '');
        String message = errorStr.substring(errorStr.indexOf(':') + 2);
        setState(() => _emailError = message);
        _shakeField(_emailFieldKey);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          title: Text(AppLocalizations.of(context)!.forgotPasswordTitle, style: AppTextStyles.subheading(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.forgotPasswordPrompt, style: AppTextStyles.body(context)),
              const SizedBox(height: 24),
              _ShakeField(
                key: _emailFieldKey,
                animation: _shakeAnimation,
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    labelText: AppLocalizations.of(context)!.email,
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : cardColor,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                    errorText: _emailError,
                  ),
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.emailRequired;
                    if (!value.contains('@')) return AppLocalizations.of(context)!.emailInvalid;
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
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleForgotPassword();
              },
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent),
              child: Text(AppLocalizations.of(context)!.sendCode, style: const TextStyle(color: Colors.white)),
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
    for (var controller in _codeControllers) controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = themeProvider.getLogoPath(context);
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!.withOpacity(0.95);

    return Scaffold(
      body: AnimatedOpacity(
        opacity: _isFading ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150), // Faster transition: 300ms -> 150ms
        curve: Curves.easeInOut, // Smoother curve
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [AppColors.darkBackground, AppColors.darkSurface] : [AppColors.lightAccent, AppColors.lightSurface],
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
                        border: Border.all(color: isDark ? AppColors.darkTextSecondary.withOpacity(0.2) : Colors.grey[400]!, width: 1),
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
                                      children: [
                                        Image.asset(logoPath, height: 80, width: 80, fit: BoxFit.contain),
                                        const SizedBox(width: 4),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'AIA',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Wallet',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.normal,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                                  icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.blue, size: 28),
                                  onPressed: _toggleTheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (!_isVerificationStep) ...[
                              Text(AppLocalizations.of(context)!.welcome, style: AppTextStyles.heading(context)),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation),
                                  child: FadeTransition(opacity: animation, child: child),
                                ),
                                child: Text(
                                  _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.createAccount,
                                  key: ValueKey(_isLogin),
                                  style: AppTextStyles.heading(context).copyWith(fontSize: 20, fontWeight: FontWeight.normal),
                                ),
                              ),
                            ],
                            if (_isVerificationStep) ...[
                              Text(AppLocalizations.of(context)!.verifyYourEmail, style: AppTextStyles.heading(context)),
                            ],
                            const SizedBox(height: 24),
                            if (!_isVerificationStep)
                              _isLogin
                                  ? Form(key: _loginFormKey, child: _buildLoginForm(cardColor))
                                  : Form(key: _registerFormKey, child: _buildRegisterForm(cardColor)),
                            if (_isVerificationStep) ...[
                              Text(AppLocalizations.of(context)!.enterCodePrompt(_emailController.text), style: AppTextStyles.body(context), textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              Form(
                                key: _verificationFormKey,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: List.generate(6, (index) {
                                        return SizedBox(
                                          width: 40,
                                          child: TextFormField(
                                            controller: _codeControllers[index],
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              filled: true,
                                              fillColor: isDark ? Colors.grey[800] : cardColor,
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                                              counterText: '',
                                            ),
                                            style: AppTextStyles.body(context).copyWith(fontSize: 20, fontWeight: FontWeight.bold, textBaseline: TextBaseline.alphabetic),
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            onChanged: (value) {
                                              if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
                                              else if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) return '';
                                              if (!RegExp(r'^\d$').hasMatch(value)) return '';
                                              return null;
                                            },
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          ),
                                        );
                                      }),
                                    ),
                                    if (_verificationError != null) ...[
                                      const SizedBox(height: 8),
                                      Text(_verificationError!, style: TextStyle(color: isDark ? Colors.redAccent : Colors.red, fontSize: 14), textAlign: TextAlign.center),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                              child: SizedBox(
                                key: ValueKey(_isLogin),
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : (_isVerificationStep ? _handleVerification : _handleAuth),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                    _isVerificationStep
                                        ? AppLocalizations.of(context)!.verify
                                        : _isLogin
                                        ? AppLocalizations.of(context)!.login
                                        : AppLocalizations.of(context)!.register,
                                    style: AppTextStyles.body(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_isVerificationStep)
                              TextButton(
                                onPressed: _toggleLoginRegister,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                  child: Text(
                                    _isLogin ? AppLocalizations.of(context)!.dontHaveAccount : AppLocalizations.of(context)!.alreadyHaveAccount,
                                    key: ValueKey(_isLogin),
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                            if (_isVerificationStep)
                              TextButton(
                                onPressed: () => setState(() {
                                  _isVerificationStep = false;
                                  for (var controller in _codeControllers) controller.clear();
                                  _verificationError = null;
                                }),
                                child: Text(AppLocalizations.of(context)!.backToRegistration, style: const TextStyle(color: Colors.blue)),
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
    );
  }

  Widget _buildLoginForm(Color cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _ShakeField(
          key: _usernameFieldKey,
          animation: _shakeAnimation,
          child: TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              labelText: AppLocalizations.of(context)!.username,
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.person, color: Colors.blue),
              helperText: _usernameController.text.length == 18 ? 'Maximum 18 characters reached' : null,
              helperStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              counterText: '',
              filled: true,
              fillColor: isDark ? Colors.grey[800] : cardColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              errorText: _usernameError,
            ),
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            maxLength: 18,
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.usernameRequired;
              if (value.length < 3) return AppLocalizations.of(context)!.usernameTooShort;
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) return 'Only letters, numbers, and underscores allowed';
              return null;
            },
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))],
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(height: 24),
        _ShakeField(
          key: _passwordFieldKey,
          animation: _shakeAnimation,
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              labelText: AppLocalizations.of(context)!.password,
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : cardColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              errorText: _passwordError,
            ),
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.passwordRequired;
              if (value.length < 6) return AppLocalizations.of(context)!.passwordTooShort;
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleAuth(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(AppLocalizations.of(context)!.forgotPassword, style: const TextStyle(color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(Color cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _ShakeField(
          key: _usernameFieldKey,
          animation: _shakeAnimation,
          child: TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              labelText: AppLocalizations.of(context)!.username,
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.person, color: Colors.blue),
              helperText: _usernameController.text.length == 18 ? 'Maximum 18 characters reached' : null,
              helperStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              counterText: '',
              filled: true,
              fillColor: isDark ? Colors.grey[800] : cardColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              errorText: _usernameError,
            ),
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            maxLength: 18,
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.usernameRequired;
              if (value.length < 3) return AppLocalizations.of(context)!.usernameTooShort;
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) return 'Only letters, numbers, and underscores allowed';
              return null;
            },
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))],
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(height: 24),
        _ShakeField(
          key: _passwordFieldKey,
          animation: _shakeAnimation,
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              labelText: AppLocalizations.of(context)!.password,
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : cardColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              errorText: _passwordError,
            ),
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.passwordRequired;
              if (value.length < 6) return AppLocalizations.of(context)!.passwordTooShort;
              return null;
            },
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(height: 24),
        _ShakeField(
          key: _emailFieldKey,
          animation: _shakeAnimation,
          child: TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              labelText: AppLocalizations.of(context)!.email,
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.email, color: Colors.blue),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : cardColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
              errorText: _emailError,
            ),
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.emailRequired;
              if (!value.contains('@')) return AppLocalizations.of(context)!.emailInvalid;
              return null;
            },
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleAuth(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShakeField extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShakeField({required Key key, required this.animation, required this.child}) : super(key: key);

  @override
  _ShakeFieldState createState() => _ShakeFieldState();
}

class _ShakeFieldState extends State<_ShakeField> {
  bool _isShaking = false;

  void shake() {
    setState(() => _isShaking = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isShaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final offset = _isShaking ? Offset(widget.animation.value * (widget.animation.status == AnimationStatus.forward ? 1 : -1), 0) : Offset.zero;
        return Transform.translate(offset: offset, child: child);
      },
      child: widget.child,
    );
  }
}