import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_login.dart'; // Ensure this is correct for VetLoginDto
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart'; // Ensure this contains ApiService and loginClient method
import 'package:veterinary_app/views/Auth_pages/vet_register_page.dart';
import 'package:veterinary_app/views/Auth_pages/verify_login_code_page.dart';
import 'package:veterinary_app/views/Auth_pages/vet_forgot_password_page.dart';
// import 'package:veterinary_app/views/components/login_navbar.dart'; // Removed custom LoginNavbar, using standard AppBar

// Assuming kPrimaryGreen and kAccentGreen are defined in main.dart
import 'package:veterinary_app/main.dart';

import '../../utils/app_colors.dart'; // Adjust path if using a separate constants.dart

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
  bool _obscurePassword = true; // For password visibility toggle

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

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
      _showSnackBar(responseMessage, isSuccess: result["success"] == true);

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
        responseMessage = 'Login failed: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          '',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450), // Slightly wider for better form layout
            padding: const EdgeInsets.all(30), // Increased padding
            margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20), // Adjusted margin
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, // Use themed card color (white)
              //borderRadius: Theme.of(context).cardTheme.shape?.borderRadius, // Use themed card border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "Welcome Back, Veterinarian!",
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sign in to access your dashboard.",
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: textTheme.bodyLarge, // Use themed text style
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined), // Modern icon
                      // Other decoration properties handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: textTheme.bodyLarge, // Use themed text style
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded), // Modern icon
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      // Other decoration properties handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading // Show CircularProgressIndicator when loading
                        ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                        : ElevatedButton(
                      onPressed: loginUser,
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                      child: Text(
                        "Login",
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (responseMessage.isNotEmpty)
                    Text(
                      responseMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: responseMessage.toLowerCase().contains('success') ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VetForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryGreen, // Themed text button color
                      ),
                      child: Text(
                        "Forgot your password?",
                        style: textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account? ",
                        style: textTheme.bodyMedium, // Use themed text style
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kAccentGreen, // Use accent green for register link
                        ),
                        child: Text(
                          "Register here",
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
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