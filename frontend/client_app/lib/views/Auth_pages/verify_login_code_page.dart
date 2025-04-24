import 'package:client_app/views/components/login_navbar.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_verify_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final verifyDto = ClientVerifyLoginDto(
      email: widget.email,
      code: codeController.text.trim(),
    );

    final result = await _apiService.verifyLoginCode(verifyDto);

    setState(() {
      isLoading = false;
      if (result['success'] == true) {
        // Store JWT and username in shared preferences
        final data = result['data'];
        final token = data['token'];
        final username = data['data']['username'];

        _storeSession(token, username);

        // Navigate to home page with username
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(username: username),
          ),
        );
      } else {
        responseMessage = result['message'] ?? 'Verification failed.';
      }
    });
  }

  Future<void> _storeSession(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('username', username);
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
                Text(responseMessage, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
