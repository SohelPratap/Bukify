import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../onboarding/pages/splash_page.dart';
import '../../onboarding/pages/role_select_page.dart'; // ✅ ADD THIS

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter a valid phone number"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _otpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("OTP sent successfully"),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _resendOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("OTP resent"),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _verifyOtp() {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter complete OTP"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // ✅ OTP VERIFIED
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("OTP verified successfully!"),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // ✅ NAVIGATE TO ROLE SELECTION PAGE
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectPage(),
        ),
      );
    });
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
              // 🔙 BACK BUTTON
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SplashPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // MAIN CONTENT
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
                        const SizedBox(height: 20),

                        // ICON
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFA855F7),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_android_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Phone Verification",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _otpSent
                              ? "Enter the 6-digit code sent to\n+91 ${_phoneController.text}"
                              : "We'll send you a one-time password\nto verify your number",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (!_otpSent)
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              labelText: "Phone Number",
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                child: Text(
                                  "+91",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              counterText: "",
                            ),
                          ),

                        if (_otpSent)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              6,
                                  (index) => SizedBox(
                                width: 50,
                                height: 60,
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _otpSent ? _verifyOtp : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              _otpSent ? "Verify OTP" : "Send OTP",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_otpSent)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _resendOtp,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Resend OTP"),
                              ),
                              const SizedBox(width: 10),
                              Text("|",
                                  style:
                                  TextStyle(color: Colors.grey[400])),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _otpSent = false;
                                    for (var c in _otpControllers) {
                                      c.clear();
                                    }
                                  });
                                },
                                child: const Text("Change Number"),
                              ),
                            ],
                          ),

                        const SizedBox(height: 30),

                        Text(
                          "By continuing, you agree to our Terms of Service and Privacy Policy",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
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
