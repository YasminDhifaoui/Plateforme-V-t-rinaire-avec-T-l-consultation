import 'package:client_app/models/auth_models/client_login.dart';
import 'package:client_app/models/auth_models/client_register.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:client_app/views/Auth_pages/client_register_page.dart';
import 'package:client_app/views/components/login_navbar.dart';
import 'package:client_app/views/Auth_pages/verify_login_code_page.dart';
import 'package:flutter/material.dart';

class ClientLoginPage extends StatefulWidget {
  const ClientLoginPage({super.key});

  @override
  State<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService();

  String responseMessage = '';

  void loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: loginUser, child: const Text("Login")),
                const SizedBox(height: 20),
                Text(responseMessage),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("You don't have an account yet? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Create account",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
