import 'package:flutter/material.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'vet_login_page.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class VetResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;

  const VetResetPasswordPage({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<VetResetPasswordPage> createState() => _VetResetPasswordPageState();
}

class _VetResetPasswordPageState extends State<VetResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ApiService _authService = ApiService();

  String responseMessage = '';
  bool isLoading = false;
  bool _obscurePassword = true; // Added for password visibility toggle
  bool _obscureConfirmPassword = true; // Added for confirm password visibility toggle

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // You can add more complex password validation rules here (e.g., strong password regex)
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required'; // Added a check for empty confirm password
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
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
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void submitResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = ''; // Clear previous message
    });

    try {
      final result = await _authService.resetPassword(
        email: widget.email,
        token: widget.token,
        newPassword: passwordController.text.trim(),
      );
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });

      _showSnackBar(responseMessage, isSuccess: result["success"] == true); // Show themed snackbar

      if (result["success"] == true) {
        if (mounted) {
          // Navigate back to login page after success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VetLoginPage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Failed to reset password: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false); // Show error snackbar
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
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
          'Reset Password',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450), // Consistent max width
            padding: const EdgeInsets.all(30), // Consistent inner padding
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
                    Icons.lock_reset_rounded, // Relevant icon for reset password
                    size: 70,
                    color: kPrimaryGreen, // Themed icon color
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Set Your New Password',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please enter a new password for ${widget.email}.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_open_rounded, color: kAccentGreen), // Modern lock icon
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
                      // Input decoration handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: kAccentGreen), // Modern lock icon
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      // Input decoration handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                        : ElevatedButton.icon(
                      onPressed: submitResetPassword,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white), // Modern reset icon
                      label: Text(
                        'Reset Password',
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Conditionally display response message (Snackbar is also used now)
                  if (responseMessage.isNotEmpty && !responseMessage.toLowerCase().contains('success'))
                    Text(
                      responseMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
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