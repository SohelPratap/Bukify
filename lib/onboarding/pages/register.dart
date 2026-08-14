import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/services/session_service.dart';
import '../../onboarding/pages/login.dart';
import '../../worker/pages/worker_home.dart';
import '../../customer/pages/customer_home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String _role = 'customer'; // default
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack("All fields are required");
      return;
    }

    try {
      setState(() => _loading = true);

      final response = await _authService.register(
        email: email,
        password: password,
        role: _role,
      );

      // ✅ SAVE SESSION (JWT + ROLE)
      await SessionService.saveSession(
        token: response.token,
        role: response.role,
      );

      if (!mounted) return;

      // ✅ ROLE-BASED REDIRECT
      if (response.role == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeWorkerPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeCustomerPage(),
          ),
        );
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[400],
      ),
    );
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
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFA855F7),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Create Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Register using email and password",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 40),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Select Role",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'customer',
                                groupValue: _role,
                                onChanged: (val) {
                                  setState(() => _role = val!);
                                },
                                title: const Text("Customer"),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'worker',
                                groupValue: _role,
                                onChanged: (val) {
                                  setState(() => _role = val!);
                                },
                                title: const Text("Worker"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Login"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}