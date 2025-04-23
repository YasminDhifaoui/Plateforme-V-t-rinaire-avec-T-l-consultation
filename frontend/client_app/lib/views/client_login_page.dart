import 'package:client_app/models/client_login.dart';
import 'package:client_app/services/client_auth_services.dart';
import 'package:client_app/views/login_navbar.dart';
import 'package:client_app/views/verify_login_code_page.dart';
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
      if (result["success"] == true) {
        // Navigate to verify login code page with email
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyLoginCodePage(email: emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Login failed: $e';
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
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
