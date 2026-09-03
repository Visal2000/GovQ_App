import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
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
  } else {
    await Firebase.initializeApp();
  }

  final prefs = await SharedPreferences.getInstance();
  loggedInUserNIC = prefs.getString('loggedInUserNIC') ?? '';
  loggedInUserName = prefs.getString('loggedInUserName') ?? '';

  if (!kIsWeb) {
    await NotificationService().init();
  }

  runApp(GovQApp(isLoggedIn: loggedInUserNIC.isNotEmpty));
}

class GovQApp extends StatelessWidget {
  final bool isLoggedIn;
  const GovQApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GovQ Citizen Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
