import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_login.dart'; // Ensure this is correct for VetLoginDto
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart'; // Ensure this contains ApiService and loginClient method
import 'package:veterinary_app/views/Auth_pages/vet_register_page.dart';
import 'package:veterinary_app/views/Auth_pages/verify_login_code_page.dart';
import 'package:veterinary_app/views/Auth_pages/vet_forgot_password_page.dart';
import 'package:veterinary_app/views/components/login_navbar.dart';

// Assuming kPrimaryGreen is defined in main.dart or a shared constants file,
// otherwise you'd define it here too:
// const Color kPrimaryGreen = Color(0xFF00A86B);

class VetLoginPage extends StatefulWidget {
  // NEW: Callback from MyHomePage/AppWrapper
  final Function(String token)? onLoginSuccessCallback;

  const VetLoginPage({super.key, this.onLoginSuccessCallback}); // MODIFIED Constructor

  @override
  State<VetLoginPage> createState() => _VetLoginPageState();
}

class _VetLoginPageState extends State<VetLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService(); // Renamed from _apiService for clarity

  String responseMessage = '';
  bool isLoading = false; // Added isLoading state

  void loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true; // Set loading true
      responseMessage = '';
    });

    final loginDto = VetLoginDto(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    try {
      final result = await _authService.loginClient(loginDto);
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
      if (result["success"] == true) {
        if (mounted) {
          // NAVIGATE TO 2FA Verification page
          Navigator.push( // Use push, not pushReplacement here
            context,
            MaterialPageRoute(
              builder: (context) => VerifyLoginCodePage(
                email: emailController.text.trim(),
                // Pass the callback to the 2FA verification page
                onLoginSuccessCallback: widget.onLoginSuccessCallback,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading false
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Re-using kPrimaryGreen from main.dart or defining locally if not shared
    final Color kPrimaryGreen = Theme.of(context).primaryColor; // A safe way to get primary green if defined in theme

    return Scaffold(
      appBar: const LoginNavbar(username: ''),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Vet Login",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.green, // You can use kPrimaryGreen here if defined or directly Colors.green
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading // Show CircularProgressIndicator when loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // You can use kPrimaryGreen here
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(fontSize: 16, color: Colors.white), // Added white color for text
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (responseMessage.isNotEmpty)
                    Text(
                      responseMessage,
                      style: TextStyle(
                        color: responseMessage.toLowerCase().contains('success') ? Colors.green : Colors.red,
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VetForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Register here",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}