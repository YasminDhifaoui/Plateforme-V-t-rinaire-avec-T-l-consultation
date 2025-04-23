import 'package:client_app/models/client_confirm_email.dart';
import 'package:flutter/material.dart';
import '../services/client_auth_services.dart';

class ClientConfirmEmailPage extends StatefulWidget {
  final String? email;

  const ClientConfirmEmailPage({super.key, this.email});

  @override
  State<ClientConfirmEmailPage> createState() => _ClientConfirmEmailPageState();
}

class _ClientConfirmEmailPageState extends State<ClientConfirmEmailPage> {
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
      responseMessage = result['message'] ?? "Unexpected error occurred.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Email")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Confirmation Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : confirmEmail,
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm Email"),
            ),
            const SizedBox(height: 20),
            Text(
              responseMessage,
              style: TextStyle(
                color:
                    responseMessage.contains("Success")
                        ? Colors.green
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
