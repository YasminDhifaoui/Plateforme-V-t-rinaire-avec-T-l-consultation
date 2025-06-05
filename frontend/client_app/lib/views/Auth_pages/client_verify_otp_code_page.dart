import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_verify_otp_code.dart'; // Import the new DTO
import 'package:client_app/services/auth_services/client_auth_services.dart'; // Your ApiService
import 'package:client_app/main.dart'; // For kPrimaryBlue, kAccentBlue. Adjust path if using separate constants.
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue


import 'client_login_page.dart';
import 'client_reset_password_page.dart'; // To navigate back to login

class ClientVerifyOtpCodePage extends StatefulWidget {
  final String email; // Receive email from the previous page

  const ClientVerifyOtpCodePage({super.key, required this.email});

  @override
  State<ClientVerifyOtpCodePage> createState() =>
      _ClientVerifyOtpCodePageState();
}

class _ClientVerifyOtpCodePageState extends State<ClientVerifyOtpCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  String responseMessage = '';

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

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  void submitOtpVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = ''; // Clear previous message
    });

    final model = ClientVerifyOtpCodeDto(
      email: widget.email, // Use the email passed from the previous page
      otpCode: otpController.text.trim(),
    );

    try {
      final result = await ApiService().verifyOtpCode(model);

      if (result["success"] == true) {
        _showSnackBar(result["message"] ?? "OTP verified successfully!", isSuccess: true);
        // Navigate to the reset password page, passing the email
        Navigator.pushReplacement( // Use pushReplacement to prevent going back to OTP page
          context,
          MaterialPageRoute(
            builder: (context) => ClientResetPasswordPage(email: widget.email),
          ),
        );
      } else {
        setState(() {
          responseMessage = result["message"] ?? "OTP verification failed.";
        });
        _showSnackBar(responseMessage, isSuccess: false);
      }
    } catch (e, stacktrace) {
      setState(() {
        responseMessage = 'Error verifying OTP: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
      print('OTP verification error: $e'); // For debugging
      print('Stacktrace: $stacktrace'); // For debugging
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Verify OTP',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                    'Verify Your Code',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'An OTP has been sent to ${widget.email}. Please enter it below.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                    maxLength: 6, // OTP is 6 digits
                    decoration: InputDecoration(
                      labelText: 'Enter OTP Code',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: kAccentBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      counterText: "", // Hide character counter
                    ),
                    validator: _validateOtp,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? CircularProgressIndicator(color: kPrimaryBlue)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitOtpVerification,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: Text(
                        'Verify Code',
                        style: textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
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

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil( // Use pushAndRemoveUntil to clear stack to login
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ClientLoginPage()),
                              (Route<dynamic> route) => false, // Clear all routes below
                        );
                      },
                      icon: Icon(Icons.login_rounded, color: kAccentBlue),
                      label: Text(
                        'Back to Login',
                        style: textTheme.labelLarge?.copyWith(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryBlue,
                        side: BorderSide(color: kPrimaryBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
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