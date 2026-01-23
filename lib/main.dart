import 'package:flutter/material.dart';

// Splash page import
import 'onboarding/pages/splash_page.dart';

void main() {
  runApp(const BukifyApp());
}

class BukifyApp extends StatelessWidget {
  const BukifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BukiFy',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),

      // App starts from Splash Page
      home: const SplashPage(),
    );
  }
}
