import 'package:client_app/models/auth_models/client_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:client_app/views/Auth_pages/client_register_page.dart';
import 'package:client_app/views/components/login_navbar.dart';
import 'package:client_app/views/Auth_pages/verify_login_code_page.dart'; // Corrected import for VerifyLoginCodePage
import 'package:client_app/views/Auth_pages/client_forgot_password_page.dart';
import 'package:flutter/material.dart';

class ClientLoginPage extends StatefulWidget {
  // NEW: Callback from HomePage/ClientAppWrapper
  final Function(String token)? onLoginSuccessCallback;

  const ClientLoginPage({super.key, this.onLoginSuccessCallback}); // MODIFIED Constructor

  @override
  State<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService();

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

    final loginDto = ClientLoginDto(
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
          // Navigate to verify login code page with email
          Navigator.push(
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
    return Scaffold(
      appBar: const LoginNavbar(),
      body: Center(
        child: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border.all(color: Colors.teal, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Using Theme.of(context).primaryColor for consistency with theme
                  Text(
                    "Client Login",
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Login", style: TextStyle(fontSize: 16)),
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
                          builder: (context) => const ClientForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Did you forget your password ?",
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
                      const Text("You don't have an account yet? "),
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
                          "Create account",
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