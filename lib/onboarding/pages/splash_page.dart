import 'package:bukify/customer/pages/customer_home.dart';
import 'package:bukify/worker/pages/worker_home.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../auth/services/session_service.dart';
import '../../onboarding/pages/login.dart';
import '../../worker/pages/worker_home.dart';
import '../../customer/pages/customer_home.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController.forward();

    Timer(const Duration(milliseconds: 700), () async {
      _fadeController.forward();
      await _checkSessionAndRedirect();
    });
  }

  Future<void> _checkSessionAndRedirect() async {
    final hasSession = await SessionService.hasSession();

    if (!mounted) return;

    if (hasSession) {
      final role = await SessionService.getRole();

      if (role == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeWorkerPage(),
          ),
        );
      } else if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeCustomerPage(),
          ),
        );
      }
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: const Text(
                        "BukiFy",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            "Welcome to",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Service provider app",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}