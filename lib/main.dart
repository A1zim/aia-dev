import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:aia_wallet/generated/app_localizations.dart';
import 'package:aia_wallet/pages/AddTransactionScreen.dart';
import 'package:aia_wallet/pages/CurrencyScreen.dart';
import 'package:aia_wallet/pages/CategoryScreen.dart';
import 'package:aia_wallet/pages/MainNavigationScreen.dart';
import 'package:aia_wallet/theme/styles.dart';
import 'package:aia_wallet/providers/theme_provider.dart';
import 'package:aia_wallet/providers/currency_provider.dart';
import 'package:aia_wallet/providers/transaction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define LocaleProvider
class LocaleProvider with ChangeNotifier {
  Locale _locale;

  LocaleProvider(this._locale);

  Locale get locale => _locale;

  void setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }
}

// Custom PageTransitionsBuilder to disable all transitions
class NoTransitionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child; // No transition animation
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved preferences
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'ky';
  final savedTheme = prefs.getString('themeMode') ?? 'system';

  // Initialize providers
  final themeProvider = ThemeProvider(initialMode: ThemeProvider().themeModeFromString(savedTheme));
  await themeProvider.loadTheme();
  final localeProvider = LocaleProvider(Locale(savedLocale));
  final transactionProvider = TransactionProvider();
  await transactionProvider.init(); // Initialize the database
  final currencyProvider = CurrencyProvider();
  await currencyProvider.loadCurrency(); // Load saved currency
  currencyProvider.setTransactionProvider(transactionProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: currencyProvider),
        ChangeNotifierProvider.value(value: transactionProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'AiaWallet',
          theme: AppTheme.lightTheme().copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.iOS: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.macOS: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.windows: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.linux: NoTransitionPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: AppTheme.darkTheme().copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.iOS: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.macOS: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.windows: NoTransitionPageTransitionsBuilder(),
                TargetPlatform.linux: NoTransitionPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ky', ''),
            Locale('ru', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          initialRoute: '/main',
          routes: {
            '/main': (context) => const MainNavigationScreen(),
            '/add_transaction': (context) => const AddTransactionScreen(),
            '/currency': (context) => const CurrencyScreen(),
            '/categories': (context) => const CategoryScreen(),
          },
          builder: (context, child) {
            // Respect user's font size settings
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: MediaQuery.of(context).textScaleFactor,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}