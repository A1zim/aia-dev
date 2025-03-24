import 'package:flutter/material.dart';
import 'package:personal_finance/pages/LoginRegister.dart';
import 'package:personal_finance/pages/MainNavigationScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginRegister(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}