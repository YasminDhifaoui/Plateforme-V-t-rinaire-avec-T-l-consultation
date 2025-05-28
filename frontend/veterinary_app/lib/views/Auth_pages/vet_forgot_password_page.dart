import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_forget_password.dart';
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart';
import 'package:veterinary_app/views/Auth_pages/vet_verify_otp_code_page.dart';
import 'package:veterinary_app/views/components/login_navbar.dart'; // Keeping LoginNavbar as it was originally

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart';

import '../../services/auth_services/vet_auth_services.dart'; // Adjust path if using a separate constants.dart file

class VetForgotPasswordPage extends StatefulWidget {
  const VetForgotPasswordPage({super.key});

  @override
  State<VetForgotPasswordPage> createState() =>
      _VetForgotPasswordPageState(); // Corrected state class name
}

class _VetForgotPasswordPageState extends State<VetForgotPasswordPage> { // Corrected state class name
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

      // Check for success and navigate to OTP page
      if (result["success"] == true) {
        _showSnackBar(responseMessage, isSuccess: true);
        // Redirect to OTP verification page on success
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VetVerifyOtpCodePage(
              email: emailController.text.trim(), // Pass the email to the OTP page
            ),
          ),
        );
      } else {
        _showSnackBar(responseMessage, isSuccess: false);
      }
    } catch (e, stacktrace) { // Added stacktrace for better debugging
      setState(() {
        responseMessage =
        'Failed to send reset password email: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
      print('Forgot password error: $e'); // For debugging
      print('Stacktrace: $stacktrace'); // For debugging
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
          'Forgot Password', // Added clear title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0), // Adjusted vertical padding
          child: Container(
            padding: const EdgeInsets.all(30), // Increased inner padding
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, // Use themed card color (white)
              borderRadius: BorderRadius.circular(15), // Consistent rounded corners
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
                    'Enter your email address below to receive a password reset code.', // Updated text to 'code'
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
                      border: OutlineInputBorder( // Explicitly define border for consistency
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
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
                        'Send Reset Code', // Updated button text to 'Code'
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                      style: ElevatedButton.styleFrom( // Explicitly define button style for consistency
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
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