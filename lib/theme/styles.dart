import 'package:flutter/material.dart';
import 'package:aia_wallet/utils/scaling.dart';

// Define the color schemes for light and dark themes
class AppColors {
  // Light theme colors
  static const Color lightPrimary = Colors.deepPurple;
  static const Color lightSecondary = Colors.pinkAccent;
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Colors.black87;
  static const Color lightTextSecondary = Colors.grey;
  static const Color lightAccent = Colors.blueAccent;
  static const Color lightError = Colors.redAccent;
  static const Color lightShadow = Colors.black26;

  // Dark theme colors
  static const Color darkPrimary = Colors.deepPurpleAccent;
  static const Color darkSecondary = Colors.pink;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.grey;
  static const Color darkAccent = Colors.blueAccent;
  static const Color darkError = Colors.redAccent;
  static const Color darkShadow = Colors.black54;

  // Chart colors (used in ReportsScreen)
  static const Map<String, Color> categoryColors = {
    'food': Colors.redAccent,
    'transport': Colors.blueAccent,
    'housing': Colors.greenAccent,
    'utilities': Colors.orangeAccent,
    'entertainment': Colors.purpleAccent,
    'healthcare': Colors.tealAccent,
    'education': Colors.pinkAccent,
    'shopping': Colors.amberAccent,
    'other_expense': Colors.cyanAccent,
    'salary': Colors.limeAccent,
    'gift': Colors.indigoAccent,
    'interest': Colors.deepOrangeAccent,
    'other_income': Colors.lightGreenAccent,
  };

  static const List<Color> fallbackColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
    Colors.deepOrange,
    Colors.lightGreen,
  ];
}

// Define text styles
class AppTextStyles {
  static TextStyle heading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: Scaling.scaleFont(24),
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextStyle subheading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: Scaling.scaleFont(18),
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: Scaling.scaleFont(16),
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextStyle label(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: Scaling.scaleFont(14),
      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    );
  }

  static TextStyle chartLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: Scaling.scaleFont(12),
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextStyle tooltip(BuildContext context) {
    return TextStyle(
      fontSize: Scaling.scaleFont(12),
      color: Colors.white,
    );
  }
}

// Define button styles
class AppButtonStyles {
  static ButtonStyle elevatedButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.styleFrom(
      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      padding: EdgeInsets.symmetric(
        horizontal: Scaling.scalePadding(16),
        vertical: Scaling.scalePadding(12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
      ),
      elevation: 4,
    );
  }

  static ButtonStyle textButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextButton.styleFrom(
      foregroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: EdgeInsets.symmetric(
        horizontal: Scaling.scalePadding(16),
        vertical: Scaling.scalePadding(12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
        side: BorderSide(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  static ButtonStyle outlinedButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      side: BorderSide(
        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        width: 1.5,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Scaling.scalePadding(16),
        vertical: Scaling.scalePadding(12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
      ),
    );
  }
}

// Define input decoration styles (for dropdowns, text fields, etc.)
class AppInputStyles {
  static InputDecoration textField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(12)),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          width: 2,
        ),
      ),
      labelStyle: AppTextStyles.label(context),
    );
  }

  static InputDecoration dropdown(BuildContext context, {String? labelText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.label(context),
      filled: true,
      fillColor: isDark
          ? AppColors.darkBackground.withOpacity(0.3)
          : AppColors.lightSurface.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(20)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(20)),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkAccent.withOpacity(0.3) : AppColors.lightAccent.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(20)),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Scaling.scalePadding(16),
        vertical: Scaling.scalePadding(12),
      ),
    );
  }

  static Widget dropdownIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      Icons.arrow_drop_down,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      size: Scaling.scaleIcon(24),
    );
  }

  static DropdownMenuItem<T> dropdownMenuItem<T>(
      BuildContext context,
      T value,
      String displayText,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownMenuItem<T>(
      value: value,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Scaling.scalePadding(8),
          horizontal: Scaling.scalePadding(12),
        ),
        child: Text(
          displayText,
          style: AppTextStyles.body(context).copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> dropdownProperties(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return {
      'style': AppTextStyles.body(context).copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      'dropdownColor': isDark ? AppColors.darkSurface : AppColors.lightSurface,
      'icon': dropdownIcon(context),
      'menuMaxHeight': Scaling.scale(300.0),
      'borderRadius': BorderRadius.circular(Scaling.scale(16)),
      'elevation': 8,
    };
  }
}

// Define card styles
class AppCardStyles {
  static Card card(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Scaling.scale(16)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightSurface, AppColors.lightBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Scaling.scale(16)),
        ),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        error: AppColors.lightError,
        onPrimary: AppColors.lightTextPrimary,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
        onError: AppColors.lightTextPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: Scaling.scaleFont(24),
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: Scaling.scaleFont(18),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(fontSize: Scaling.scaleFont(16)),
        bodyMedium: TextStyle(fontSize: Scaling.scaleFont(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          backgroundColor: AppColors.lightPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Scaling.scale(16)),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.darkError,
        onPrimary: AppColors.darkTextPrimary,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: AppColors.darkTextPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: Scaling.scaleFont(24),
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: Scaling.scaleFont(18),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(fontSize: Scaling.scaleFont(16)),
        bodyMedium: TextStyle(fontSize: Scaling.scaleFont(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          backgroundColor: AppColors.darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Scaling.scale(12)),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Scaling.scale(16)),
        ),
      ),
      useMaterial3: true,
    );
  }
}