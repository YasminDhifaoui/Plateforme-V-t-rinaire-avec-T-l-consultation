import 'package:client_app/models/client_login.dart';
import 'package:client_app/services/client_auth_services.dart';
import 'package:flutter/material.dart';

class ClientLoginPage extends StatefulWidget {
  const ClientLoginPage({super.key});

  @override
  State<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService();

  String responseMessage = '';

  void loginUser() async {
    final loginDto = ClientLoginDto(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    try {
      final result = await _authService.loginClient(loginDto);
      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });
    } catch (e) {
      setState(() {
        responseMessage = 'Login failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: loginUser, child: const Text("Login")),
            const SizedBox(height: 20),
            Text(responseMessage),
          ],
        ),
      ),
    );
  }
}
