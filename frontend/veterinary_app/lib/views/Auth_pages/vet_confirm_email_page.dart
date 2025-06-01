import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_confirm_email.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart';
import 'package:veterinary_app/views/components/login_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart';

import '../../utils/app_colors.dart'; // Adjust path if using a separate constants.dart file

class VetConfirmEmailPage extends StatefulWidget {
  final String? email;

  const VetConfirmEmailPage({super.key, this.email});

  @override
  State<VetConfirmEmailPage> createState() => _VetConfirmEmailPageState();
}

class _VetConfirmEmailPageState extends State<VetConfirmEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  final TextEditingController codeController = TextEditingController();
  final ApiService _authService = ApiService();

  String responseMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

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

  void confirmEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final confirmDto = VetConfirmEmailDto(
      email: emailController.text.trim(),
      code: codeController.text.trim(),
    );

    try {
      final result = await _authService.ConfirmEmail(confirmDto);

      setState(() {
        isLoading = false;
      });

      final message = result['message'] ?? "Unexpected error occurred.";
      _showSnackBar(message, isSuccess: result['success']);

      if (result['success'] == true) {
        if (mounted) {
          // Changed to pushReplacement to prevent going back to confirmation page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const VetLoginPage(),
            ),
          );
        }
      } else {
        setState(() {
          responseMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        responseMessage = 'Failed to confirm email: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation code is required';
    }
    return null;
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
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450), // Increased max width
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
                    Icons.email_outlined, // Modern email icon
                    size: 80,
                    color: kPrimaryGreen, // Themed icon color
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Your Email',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We have sent a verification code to:',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.email ?? '',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: codeController,
                    keyboardType: TextInputType.number, // Ensure numeric keyboard
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 5.0), // Spaced out for code
                    maxLength: 6, // Typically 6 digits for confirmation code
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit code',
                      hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade400),
                      // Input decoration handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateCode,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                        : ElevatedButton(
                      onPressed: confirmEmail,
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                      child: Text(
                        'Confirm Email',
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Conditionally display response message
                  if (responseMessage.isNotEmpty)
                    Text(
                      responseMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: responseMessage.toLowerCase().contains('success') ? Colors.green.shade700 : Colors.red.shade700,
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