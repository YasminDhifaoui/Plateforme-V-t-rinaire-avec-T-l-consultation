import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_confirm_email.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart';
import 'package:veterinary_app/views/components/login_navbar.dart';

// Define your green theme color (match with login/register page)
const Color kPrimaryGreen = Color(
  0xFF00A86B,
); // Change if your green is different

class VetConfirmEmailPage extends StatefulWidget {
  final String? email;

  const VetConfirmEmailPage({super.key, this.email});

  @override
  State<VetConfirmEmailPage> createState() => _VetConfirmEmailPageState();
}

class _VetConfirmEmailPageState extends State<VetConfirmEmailPage> {
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    final confirmDto = VetConfirmEmailDto(
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
        builder:
            (context) => AlertDialog(
              title: const Text('Email Confirmed'),
              content: Text('$message\nPlease try logging in.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const VetLoginPage(),
                      ),
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
      appBar: LoginNavbar(username: ''),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.05),
            border: Border.all(color: kPrimaryGreen, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirm your email by entering the confirmation code sent to:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.email ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: "Confirmation Code",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryGreen),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: kPrimaryGreen.withOpacity(0.6),
                      ),
                    ),
                  ),
                  validator: _validateCode,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : confirmEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                  ),
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
                        responseMessage.toLowerCase().contains("success")
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
