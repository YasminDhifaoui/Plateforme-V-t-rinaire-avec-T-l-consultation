import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue
import 'package:client_app/views/components/login_navbar.dart'; // Keep this import if LoginNavbar is custom and needed elsewhere
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_forget_password.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart';

import 'client_login_page.dart';
import 'client_verify_otp_code_page.dart'; // Adjust path if using a separate constants.dart

class ClientForgotPasswordPage extends StatefulWidget {
  const ClientForgotPasswordPage({super.key});

  @override
  State<ClientForgotPasswordPage> createState() =>
      _ClientForgotPasswordPageState();
}

class _ClientForgotPasswordPageState extends State<ClientForgotPasswordPage> {
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

  // Helper to show themed SnackBar feedback
  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = ''; // Clear previous message
    });

    final model = ClientForgetPasswordDto(email: emailController.text.trim());

    try {
      final result = await ApiService().forgotPassword(model);
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });

      // Check for success and navigate
      if (result["success"] == true) {
        _showSnackBar(responseMessage, isSuccess: true);
        // Redirect to OTP verification page on success
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientVerifyOtpCodePage(
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
      backgroundColor: Colors.grey.shade50, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Login', // Tooltip for clarity
        ),
        title: Text(
          'Forgot Password', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: Center(
        child: SingleChildScrollView( // Use SingleChildScrollView for keyboard overflow
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Container(
            padding: const EdgeInsets.all(24.0), // Increased inner padding
            decoration: BoxDecoration(
              color: Colors.white, // White background for the form card
              borderRadius: BorderRadius.circular(15), // More rounded corners
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reset Your Password',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter your email address below to receive a password reset code.', // Changed 'link' to 'code' for OTP flow
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      prefixIcon: Icon(Icons.email_outlined, color: kAccentBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100, // Light grey fill
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? CircularProgressIndicator(color: kPrimaryBlue) // Themed loading indicator
                      : SizedBox(
                    width: double.infinity, // Make button full width
                    child: ElevatedButton.icon(
                      onPressed: submitForgotPassword,
                      icon: const Icon(Icons.send_rounded, color: Colors.white), // Modern send icon
                      label: Text(
                        'Send Reset Code', // Changed 'Link' to 'Code'
                        style: textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue, // Themed button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // More rounded
                        ),
                        elevation: 6, // Subtle shadow
                      ),
                    ),
                  ),
                  if (responseMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
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
                  ],
                  const SizedBox(height: 20),
                  SizedBox( // Wrap with SizedBox to give it full width
                    width: double.infinity,
                    child: OutlinedButton.icon( // Changed from TextButton to OutlinedButton
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ClientLoginPage()),
                        );
                      },
                      icon: Icon(Icons.login_rounded, color: kAccentBlue), // Login icon
                      label: Text(
                        'Back to Login',
                        style: textTheme.labelLarge?.copyWith(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryBlue, // Text and icon color
                        side: BorderSide(color: kPrimaryBlue, width: 1.5), // Themed border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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