import 'package:flutter/material.dart';
import '../models/client_register.dart';
import '../services/client_auth_services.dart';
import 'client_confirm_email_page.dart';
import 'login_navbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isLoading = false;
  String? message;

  void register() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    final client = ClientRegister(
      email: emailController.text,
      username: usernameController.text,
      password: passwordController.text,
    );

    final result = await apiService.registerClient(client);

    setState(() {
      isLoading = false;
      message = result["message"];
    });

    if (result["success"]) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Check your email to confirm.")));

      // Navigate to confirm email page with email parameter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientConfirmEmailPage(
            email: emailController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LoginNavbar(),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register, child: Text("Register")),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message!, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
