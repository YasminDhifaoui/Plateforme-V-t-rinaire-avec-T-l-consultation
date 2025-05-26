import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veterinary_app/models/auth_models/vet_verify_login.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/views/components/login_navbar.dart';
import '../home_page.dart'; // Still needed as you navigate to it from here

// Assuming kPrimaryGreen is defined in main.dart or a shared constants file,
// otherwise you'd define it here too:
// const Color kPrimaryGreen = Color(0xFF00A86B);

class VerifyLoginCodePage extends StatefulWidget {
  final String email;
  // NEW: Callback for SignalR init received from previous page
  final Function(String token)? onLoginSuccessCallback;

  // MODIFIED Constructor
  const VerifyLoginCodePage({
    super.key,
    required this.email,
    this.onLoginSuccessCallback, // Make sure this is present
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

  void verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
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
        final username = data['data'] != null ? data['data']['username'] : '';

        if (token.isEmpty || username.isEmpty) {
          setState(() {
            responseMessage = 'Invalid token or username received.';
            isLoading = false;
          });
          return;
        }

        await _storeSession(token, username);

        // *** CALL THE GLOBAL SIGNALR INITIALIZATION HERE ***
        // This will trigger the initSignalRAndListenGlobally method in AppWrapper (in main.dart)
        widget.onLoginSuccessCallback?.call(token); // Crucial call here

        if (mounted) {
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
    // Re-using kPrimaryGreen from main.dart or defining locally if not shared
    final Color kPrimaryGreen = Theme.of(context).primaryColor; // A safe way to get primary green if defined in theme

    return Scaffold(
      appBar: LoginNavbar(username: ''),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.05),
            border: Border.all(color: kPrimaryGreen, width: 2),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryGreen),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: kPrimaryGreen.withOpacity(0.6),
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
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Verify'),
                ),
                const SizedBox(height: 20),
                Text(
                  responseMessage,
                  style: TextStyle(
                    color:
                    responseMessage.toLowerCase().contains('success')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}