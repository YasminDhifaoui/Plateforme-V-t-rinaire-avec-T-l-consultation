import 'package:flutter/material.dart';
import '../models/client_register.dart';
import '../services/client_auth_services.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                : ElevatedButton(onPressed: register, child: Text("Register")),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
