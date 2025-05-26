import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/views/components/login_navbar.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_verify_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import '../home_page.dart'; // Assuming this is your client's actual home page

class VerifyLoginCodePage extends StatefulWidget {
  final String email;
  // NEW: Add the onLoginSuccessCallback parameter
  final Function(String token)? onLoginSuccessCallback;

  const VerifyLoginCodePage({
    Key? key,
    required this.email,
    this.onLoginSuccessCallback, // Make sure this is present
  }) : super(key: key);

  @override
  _VerifyLoginCodePageState createState() => _VerifyLoginCodePageState();
}

class _VerifyLoginCodePageState extends State<VerifyLoginCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final ApiService _apiService = ApiService();

  String responseMessage = '';
  bool isLoading = false;

  void verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

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
      print('Result: $result');

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final token = data['token'];
        final userData = data['data']; // this is a nested map
        final userId = userData['clientId']; // Assuming this is the correct key for user ID
        final username = userData['username']; // Assuming this is the correct key for username

        print('Token: $token');
        print('User ID: $userId');
        print('Username: $username');

        if (token == null || token.toString().isEmpty ||
            userId == null || userId.toString().isEmpty ||
            username == null || username.toString().isEmpty) {
          setState(() {
            responseMessage = 'Invalid token or user data received.';
            isLoading = false;
          });
          return;
        }

        await _storeSession(token, userId.toString()); // Ensure userId is string for token service

        // *** CRUCIAL: Call the global SignalR initialization callback here ***
        widget.onLoginSuccessCallback?.call(token.toString()); // Ensure token is string

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: username),
            ),
          );
        }
      } else {
        setState(() {
          responseMessage = result['message'] ?? 'Verification failed.';
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _storeSession(String token, String userId) async {
    await TokenService.saveToken(token, userId);
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context).primaryColor (which is Colors.teal for client app)
    final Color primaryTeal = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: const LoginNavbar(),
      body: Center(
        child: SingleChildScrollView( // Added SingleChildScrollView for safety
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: primaryTeal.withBlue(0), // Use primaryTeal for consistent theming
              border: Border.all(color: primaryTeal, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the verification code sent to ${widget.email}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16), // Added SizedBox for spacing
                  TextFormField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryTeal),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTeal.withOpacity(0.6),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Verification code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white, // Ensure text is visible
                    ),
                    child: const Text('Verify'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    responseMessage,
                    style: TextStyle(
                      color: responseMessage.toLowerCase().contains('success')
                          ? Colors.green
                          : Colors.red,
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