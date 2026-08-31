import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GovQApp());
}

class GovQApp extends StatelessWidget {
  const GovQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GovQ Citizen Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
