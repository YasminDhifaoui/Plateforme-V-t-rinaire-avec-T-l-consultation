import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/views/components/login_navbar.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_verify_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import '../home_page.dart';

class VerifyLoginCodePage extends StatefulWidget {
  final String email;

  const VerifyLoginCodePage({Key? key, required this.email}) : super(key: key);

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

        final token = result['token'];
        final userData = result['data'];
        final userId = userData['clientId'];
        final username = userData['username'];

        print('Token: $token');
        print('User ID: $userId');
        print('Username: $username');

        if (token.isEmpty || userId.isEmpty || username.isEmpty) {
          setState(() {
            responseMessage = 'Invalid token or user data received.';
            isLoading = false;
          });
          return;
        }

        await _storeSession(token, userId);

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
    return Scaffold(
      appBar: const LoginNavbar(),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter the verification code sent to ${widget.email}'),
                TextFormField(
                  controller: codeController,
                  decoration:
                  const InputDecoration(labelText: 'Verification Code'),
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
                  child: const Text('Verify'),
                ),
                const SizedBox(height: 20),
                Text(responseMessage,
                    style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
