import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/pages/LoginRegister.dart';
import 'package:personal_finance/pages/MainNavigationScreen.dart';
import 'package:personal_finance/pages/AddTransactionScreen.dart';
import 'package:personal_finance/pages/HomeScreen.dart';
import 'package:personal_finance/pages/ReportsScreen.dart';
import 'package:personal_finance/pages/SettingsScreen.dart';
import 'package:personal_finance/pages/TransactionHistoryScreen.dart';
import 'package:personal_finance/theme/styles.dart';
import 'package:personal_finance/providers/theme_provider.dart';
import 'package:personal_finance/providers/locale_provider.dart';
import 'package:personal_finance/localization/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
          // TODO: Локализовать title через .arb файлы (рекомендуется).
          // Нельзя использовать AppLocalizations.of(context) здесь, так как локализация ещё не настроена.
          title: 'Personal Finance', // Оставляем как есть, но рекомендуется локализовать через .arb
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: LocaleProvider.supportedLocales.map((lang) => Locale(lang, '')).toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supported in supportedLocales) {
              if (locale != null && locale.languageCode == supported.languageCode) {
                return supported;
              }
            }
            return supportedLocales.first; // По умолчанию 'en'
          },
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginRegister(),
            '/main': (context) => const MainNavigationScreen(),
            '/add_transaction': (context) => const AddTransactionScreen(),
            '/reports': (context) => const ReportsScreen(),
            '/history': (context) => const TransactionHistoryScreen(),
            '/settings': (context) => SettingsScreen(
              onThemeToggle: () {
                themeProvider.toggleTheme();
              },
            ),
          },
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context).error, // Локализуем "Page not found" через ключ 'error'
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}