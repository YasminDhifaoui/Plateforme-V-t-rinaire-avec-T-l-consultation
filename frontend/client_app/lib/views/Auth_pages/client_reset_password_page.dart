import 'package:flutter/material.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'client_login_page.dart';

class ClientResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;

  const ClientResetPasswordPage({super.key, required this.email, required this.token});

  @override
  State<ClientResetPasswordPage> createState() => _ClientResetPasswordPageState();
}

class _ClientResetPasswordPageState extends State<ClientResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ApiService _authService = ApiService();

  String responseMessage = '';
  bool isLoading = false;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void submitResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    try {
      final result = await _authService.resetPassword(
        email: widget.email,
        token: widget.token,
        newPassword: passwordController.text.trim(),
      );
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
      if (result["success"] == true) {
        // Navigate back to login page after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClientLoginPage()),
        );
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Failed to reset password: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                Text('Reset password for: ${widget.email}'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitResetPassword,
                        child: const Text('Reset Password'),
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
    );
  }
}
