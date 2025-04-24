import 'package:client_app/models/auth_models/client_confirm_email.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:flutter/material.dart';
import 'package:client_app/views/components/login_navbar.dart';
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

    final result = await _authService.ConfirmEmail(confirmDto);

    setState(() {
      isLoading = false;
    });

    final message = result['message'] ?? "Unexpected error occurred.";

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email Confirmed'),
          content: Text('$message\nPlease try logging in.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const ClientLoginPage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        responseMessage = message;
      });
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation code is required';
    }
    return null;
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
                const Text(
                  'Confirm your email by entering the confirmation code send to this email:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.email ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration:
                      const InputDecoration(labelText: "Confirmation Code"),
                  validator: _validateCode,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : confirmEmail,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm Email"),
                ),
                const SizedBox(height: 20),
                Text(
                  responseMessage,
                  style: TextStyle(
                    color: responseMessage.contains("Success")
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
