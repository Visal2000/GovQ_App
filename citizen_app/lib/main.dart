import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBIaPSEk3nsZRrWo0xjbg3OXlTLuXoqqDk",
      authDomain: "govq-d6d0c.firebaseapp.com",
      projectId: "govq-d6d0c",
      storageBucket: "govq-d6d0c.firebasestorage.app",
      messagingSenderId: "712217903276",
      appId: "1:712217903276:web:faf5abcb309f76e181df09",
      measurementId: "G-81RQ01H4P5",
    ),
  );
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
