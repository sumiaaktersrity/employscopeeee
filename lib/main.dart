import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const EmployScopeApp());
}

class EmployScopeApp extends StatelessWidget {
  const EmployScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmployScope',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // swap for your real app font later
        scaffoldBackgroundColor: const Color(0xFF0F1E33),
      ),
      // For now this opens straight into the Week 5 dashboard so you can
      // see/test it immediately. Once you rebuild your Login/Signup
      // screens in code, change `home` to point to Login instead, and
      // navigate to DashboardScreen after a successful login.
      home: const DashboardScreen(),
    );
  }
}
