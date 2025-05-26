import 'package:client_app/models/auth_models/client_confirm_email.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:flutter/material.dart';
// Import the blue color constants from main.dart
import 'package:client_app/main.dart';
import 'package:client_app/views/Auth_pages/client_login_page.dart';

class ClientConfirmEmailPage extends StatefulWidget {
  final String? email;

  const ClientConfirmEmailPage({super.key, this.email});

  @override
  State<ClientConfirmEmailPage> createState() => _ClientConfirmEmailPageState();
}

class _ClientConfirmEmailPageState extends State<ClientConfirmEmailPage> {
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

  // Custom dialog for success message
  void _showSuccessDialog(BuildContext context, String message) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap OK
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Email Confirmed!',
                  style: textTheme.headlineSmall?.copyWith(color: kPrimaryBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$message\nYou can now log in to your account.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const ClientLoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Proceed to Login', style: textTheme.labelLarge),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void confirmEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final confirmDto = ClientConfirmEmailDto(
      email: emailController.text.trim(),
      code: codeController.text.trim(),
    );

    try {
      final result = await _authService.ConfirmEmail(confirmDto);

      setState(() {
        isLoading = false;
      });

      final message = result['message'] ?? "Unexpected error occurred.";

      if (result['success'] == true) {
        _showSuccessDialog(context, message);
      } else {
        setState(() {
          responseMessage = message;
        });
        // Show error message via SnackBar for non-success cases
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        responseMessage = 'Confirmation failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Confirmation failed: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation code is required';
    }
    // You might add more specific validation for the code format if known (e.g., 6 digits)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please enter the 6-digit confirmation code sent to:',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.email ?? 'your_email@example.com', // Display email or a placeholder
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: codeController,
                      keyboardType: TextInputType.number, // Expecting numeric code
                      textAlign: TextAlign.center, // Center the code input
                      style: textTheme.headlineSmall?.copyWith(letterSpacing: 8.0), // Spaced out for code input
                      decoration: InputDecoration(
                        labelText: "Confirmation Code",
                        hintText: "******",
                        prefixIcon: const Icon(Icons.vpn_key, color: kAccentBlue), // Icon for code
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        labelStyle: textTheme.bodyMedium,
                        hintStyle: textTheme.bodySmall?.copyWith(color: Colors.black38),
                      ),
                      validator: _validateCode,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: isLoading
                          ? CircularProgressIndicator(color: kPrimaryBlue)
                          : ElevatedButton(
                        onPressed: confirmEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text("Confirm Email", style: textTheme.labelLarge),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Displaying API response message if any (for errors, success is handled by dialog)
                    if (responseMessage.isNotEmpty && !isLoading && !responseMessage.toLowerCase().contains('success'))
                      Text(
                        responseMessage,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Optional: Resend Code button

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}