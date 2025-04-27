import 'package:client_app/views/components/login_navbar.dart';
import 'package:flutter/material.dart';
import 'package:client_app/models/auth_models/client_forget_password.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'client_login_page.dart';

class ClientForgotPasswordPage extends StatefulWidget {
  const ClientForgotPasswordPage({super.key});

  @override
  State<ClientForgotPasswordPage> createState() =>
      _ClientForgotPasswordPageState();
}

class _ClientForgotPasswordPageState extends State<ClientForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  String responseMessage = '';
  bool isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  void submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final model = ClientForgetPasswordDto(email: emailController.text.trim());

    try {
      final result = await ApiService().forgotPassword(model);
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
    } catch (e) {
      setState(() {
        responseMessage =
            'Failed to send reset password email: ${e.toString()}';
      });
      print('Forgot password error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitForgotPassword,
                        child: const Text('Send Reset Link'),
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
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ClientLoginPage()),
                    );
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
