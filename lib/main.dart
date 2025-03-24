import 'package:flutter/material.dart';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Personal Finance',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginRegister(),
              '/main': (context) => const MainNavigationScreen(),
              '/add_transaction': (context) => const AddTransactionScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/history': (context) => const TransactionHistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}