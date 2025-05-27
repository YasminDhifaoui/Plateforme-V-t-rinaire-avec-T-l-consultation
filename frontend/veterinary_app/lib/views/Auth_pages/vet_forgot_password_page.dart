import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_forget_password.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/views/components/login_navbar.dart'; // Keeping LoginNavbar as it was originally
import 'vet_login_page.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class VetForgotPasswordPage extends StatefulWidget {
  const VetForgotPasswordPage({super.key});

  @override
  State<VetForgotPasswordPage> createState() =>
      _ClientForgotPasswordPageState(); // Original state class name
}

class _ClientForgotPasswordPageState extends State<VetForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  String responseMessage = '';
  bool isLoading = false;

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

  // Helper to show themed SnackBar feedback (added for consistency)
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

  void submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      responseMessage = ''; // Clear previous message
    });

    final model = VetForgetPasswordDto(email: emailController.text.trim());

    try {
      final result = await ApiService().forgotPassword(model);
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
      _showSnackBar(responseMessage, isSuccess: responseMessage.toLowerCase().contains('success'));
    } catch (e) {
      setState(() {
        responseMessage =
        'Failed to send reset password email: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
      print('Forgot password error: $e'); // For debugging
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Using the custom LoginNavbar as per original code
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
      ),      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0), // Adjusted vertical padding
          child: Container(
            padding: const EdgeInsets.all(30), // Increased inner padding
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, // Use themed card color (white)
              //borderRadius: Theme.of(context).cardTheme.shape?.borderRadius, // Use themed card border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_reset_rounded, // Modern reset password icon
                    size: 70,
                    color: kPrimaryGreen, // Themed icon color
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Your Password',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your email address below to receive a password reset link.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: kAccentGreen), // Themed icon
                      // Input decoration handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitForgotPassword,
                      icon: const Icon(Icons.send_rounded, color: Colors.white), // Modern send icon
                      label: Text(
                        'Send Reset Link',
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (responseMessage.isNotEmpty)
                    Text(
                      responseMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: responseMessage.toLowerCase().contains('success')
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon( // Changed to OutlinedButton for better visual distinction
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VetLoginPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.login_rounded, color: kPrimaryGreen), // Themed icon
                      label: Text(
                        'Back to Login',
                        style: textTheme.labelLarge?.copyWith(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryGreen, // Text and icon color
                        side: BorderSide(color: kPrimaryGreen, width: 1.5), // Themed border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0, // No shadow for outlined button
                      ),
                    ),
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