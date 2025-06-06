import 'package:client_app/services/auth_services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_verify_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:client_app/views/home_page.dart'; // Assuming this is your client's actual home page

// CORRECTED IMPORT: Import the blue color constants from your centralized app_colors.dart
import 'package:client_app/utils/app_colors.dart'; // <--- KEEP THIS LINE

// This import is still needed for navigatorKey if you use it for global navigation
import '../../main.dart'; // Needed for navigatorKey if used for global navigation (e.g., in AuthService.logout)


class VerifyLoginCodePage extends StatefulWidget {
  final String email;
  final Function(String token, String userId, String username)? onLoginSuccessCallback;

  const VerifyLoginCodePage({
    Key? key,
    required this.email,
    this.onLoginSuccessCallback,
  }) : super(key: key);

  @override
  State<VerifyLoginCodePage> createState() => _VerifyLoginCodePageState();
}

class _VerifyLoginCodePageState extends State<VerifyLoginCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final ApiService _apiService = ApiService(); // Assuming ApiService is your client_auth_services

  String responseMessage = '';
  bool isLoading = false;

  void _showSuccessDialog(BuildContext context, String username, String token, String userId) {
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
                Icon(Icons.verified_user, color: Colors.green.shade600, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Verification Successful!',
                  style: textTheme.headlineSmall?.copyWith(color: kPrimaryBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $username! You are now logged in.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      // Navigate to HomePage after successful verification and dialog dismissal
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          // Pass all required initial data to HomePage
                          builder: (context) => HomePage(username: username, token: token, initialUserId: userId,),
                        ),
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
                    child: Text('Continue to Home', style: textTheme.labelLarge),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void verifyCode() async {
    print('[VerifyLoginCodePage] verifyCode() called.'); // DEBUG: Function entry
    if (!_formKey.currentState!.validate()) {
      print('[VerifyLoginCodePage] Form validation failed.'); // DEBUG: Validation failed
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    try {
      final verifyDto = ClientVerifyLoginDto(
        email: widget.email,
        code: codeController.text.trim(),
      );

      final result = await _apiService.verifyLoginCode(verifyDto);
      print('[VerifyLoginCodePage] API Response Result: $result'); // DEBUG: API response

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final token = data['token'];
        final userData = data['data']; // this is a nested map
        final userId = userData['clientId']; // Assuming this is the correct key for user ID for clients
        final username = userData['username']; // Assuming this is the correct key for username

        print('[VerifyLoginCodePage] Extracted Token: $token'); // DEBUG: Extracted values
        print('[VerifyLoginCodePage] Extracted User ID: $userId');
        print('[VerifyLoginCodePage] Extracted Username: $username');

        if (token == null || token.toString().isEmpty ||
            userId == null || userId.toString().isEmpty ||
            username == null || username.toString().isEmpty) {
          setState(() {
            responseMessage = 'Invalid token or user data received.';
            isLoading = false;
          });
          print('[VerifyLoginCodePage] Error: Invalid token or user data received. Token: ${token}, UserID: ${userId}, Username: ${username}'); // DEBUG: Invalid data
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
          return;
        }

        await _storeSession(token.toString(), userId.toString(), username.toString());
        print('[VerifyLoginCodePage] Session stored locally.'); // DEBUG: Session stored

        // *** CRUCIAL: Call the global SignalR initialization callback here ***
        print('[VerifyLoginCodePage] Calling onLoginSuccessCallback...'); // DEBUG: About to call callback
        print('[VerifyLoginCodePage] Callback is null: ${widget.onLoginSuccessCallback == null}'); // DEBUG: Check if callback is null

        widget.onLoginSuccessCallback?.call(token.toString(), userId.toString(), username.toString());
        print('[VerifyLoginCodePage] onLoginSuccessCallback called.'); // DEBUG: Callback called

        if (mounted) {
          _showSuccessDialog(context, username.toString(), token.toString(), userId.toString());
        }
      } else {
        setState(() {
          responseMessage = result['message'] ?? 'Verification failed.';
        });
        print('[VerifyLoginCodePage] API Success is false or data is null. Message: ${responseMessage}'); // DEBUG: API failed
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
        responseMessage = 'An error occurred: $e';
      });
      print('[VerifyLoginCodePage] Catch block error: $e'); // DEBUG: Caught error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _storeSession(String token, String userId, String username) async {
    await TokenService.saveToken(token, userId, username);
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
                      'Enter Verification Code',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A 6-digit code has been sent to:',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(letterSpacing: 8.0),
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '******',
                        prefixIcon: const Icon(Icons.vpn_key, color: kAccentBlue),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Verification code is required';
                        }
                        if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid 6-digit code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: isLoading
                          ? CircularProgressIndicator(color: kPrimaryBlue)
                          : ElevatedButton(
                        onPressed: verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text('Verify', style: textTheme.labelLarge),
                      ),
                    ),
                    const SizedBox(height: 20),
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