import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veterinary_app/models/auth_models/vet_verify_login.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
// Removed unused LoginNavbar import as per your specified AppBar structure
import '../home_page.dart'; // Still needed as you navigate to it from here

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class VerifyLoginCodePage extends StatefulWidget {
  final String email;
  // Callback for SignalR init received from previous page
  final Function(String token)? onLoginSuccessCallback;

  const VerifyLoginCodePage({
    super.key,
    required this.email,
    this.onLoginSuccessCallback,
  });

  @override
  _VerifyLoginCodePageState createState() => _VerifyLoginCodePageState();
}

class _VerifyLoginCodePageState extends State<VerifyLoginCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final ApiService _apiService = ApiService();

  String responseMessage = '';
  bool isLoading = false;

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

  void verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = ''; // Clear previous message
    });

    try {
      final verifyDto = VetVerifyLoginDto(
        email: widget.email,
        code: codeController.text.trim(),
      );

      final result = await _apiService.verifyLoginCode(verifyDto);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final token = data['token'] ?? '';
        final username = data['data'] != null ? data['data']['username'] : ''; // Assuming 'username' is nested under 'data' key

        if (token.isEmpty || username.isEmpty) {
          setState(() {
            responseMessage = 'Invalid token or username received.';
            isLoading = false;
          });
          _showSnackBar(responseMessage, isSuccess: false);
          return;
        }

        await _storeSession(token, username);

        // Call the global SignalR initialization here
        widget.onLoginSuccessCallback?.call(token); // Crucial call here

        if (mounted) {
          _showSnackBar('Verification successful! Welcome.', isSuccess: true);
          // Navigate to HomePage after successful verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: username, token: token),
            ),
          );
        }
      } else {
        setState(() {
          responseMessage = result['message'] ?? 'Verification failed.';
        });
        _showSnackBar(responseMessage, isSuccess: false);
      }
    } catch (e) {
      setState(() {
        responseMessage = 'An error occurred: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _storeSession(String token, String username) async { // Changed userId to username for clarity
    await TokenService.saveToken(token, username);
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // App Bar styled EXACTLY as requested
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          '', // Empty title as requested
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
          padding: const EdgeInsets.all(24.0),
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
                    Icons.verified_user_rounded, // Relevant icon for verification
                    size: 70,
                    color: kPrimaryGreen, // Themed icon color
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Two-Factor Verification',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please enter the 6-digit code sent to:',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.email,
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
                    maxLength: 6, // Typically 6 digits for verification code
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade400),
                      // Input decoration handled by InputDecorationTheme in main.dart
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Verification code is required';
                      }
                      if (value.length < 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                        : ElevatedButton.icon(
                      onPressed: verifyCode,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white), // Themed icon
                      label: Text(
                        'Verify',
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Conditionally display response message
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}