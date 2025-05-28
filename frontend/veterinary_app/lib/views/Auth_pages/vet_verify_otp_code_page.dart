import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_verify_otp_code.dart'; // Import the correct Vet DTO
import 'package:veterinary_app/main.dart'; // For kPrimaryBlue, kAccentBlue. Adjust path if using separate constants.
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart';
import 'package:veterinary_app/views/Auth_pages/vet_reset_password_page.dart';
import 'package:veterinary_app/models/auth_models/vet_forget_password.dart';

import '../../services/auth_services/vet_auth_services.dart'; // Needed for resending OTP

class VetVerifyOtpCodePage extends StatefulWidget {
  final String email; // Receives email from the previous page

  const VetVerifyOtpCodePage({super.key, required this.email});

  @override
  State<VetVerifyOtpCodePage> createState() =>
      _VetVerifyOtpCodePageState();
}

class _VetVerifyOtpCodePageState extends State<VetVerifyOtpCodePage> {
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
        backgroundColor: isSuccess ? kAccentGreen : Colors.red.shade600,
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
    // Assuming a 6-digit OTP
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

    final model = VetVerifyOtpCodeDto(
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
            builder: (context) => VetResetPasswordPage(email: widget.email),
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
      print('Vet OTP verification error: $e'); // For debugging
      print('Stacktrace: $stacktrace'); // For debugging
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to re-request OTP
  void _resendOtp() async {
    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final model = VetForgetPasswordDto(email: widget.email); // Use the email from this page

    try {
      final result = await ApiService().forgotPassword(model); // Call the forgot password API again
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
      _showSnackBar(responseMessage, isSuccess: result["success"] == true);
    } catch (e) {
      setState(() {
        responseMessage = 'Failed to re-send OTP: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
      print('Re-send OTP error: $e');
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
        backgroundColor: kAccentGreen,
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
                      color: kAccentGreen,
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
                      labelStyle: TextStyle(color: kAccentGreen),
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: kAccentGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kAccentGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kAccentGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      counterText: "", // Hide character counter
                    ),
                    validator: _validateOtp,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? CircularProgressIndicator(color: kAccentGreen)
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
                        backgroundColor: kAccentGreen,
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
                  // Resend OTP button

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Clear navigation stack and go to login
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VetLoginPage()), // Assuming VetLoginPage exists
                              (Route<dynamic> route) => false,
                        );
                      },
                      icon: Icon(Icons.login_rounded, color: kAccentGreen),
                      label: Text(
                        'Back to Login',
                        style: textTheme.labelLarge?.copyWith(
                          color: kAccentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAccentGreen,
                        side: BorderSide(color: kAccentGreen, width: 1.5),
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