import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_register.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/views/Auth_pages/vet_confirm_email_page.dart';
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart';
import 'package:veterinary_app/views/components/login_navbar.dart'; // Keeping LoginNavbar as it was originally

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isLoading = false;
  String? message;
  // Removed _obscurePassword state as it was a functional change.

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      message = null;
    });

    final client = VetRegister(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check your email to confirm.")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VetConfirmEmailPage(email: emailController.text),
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // The original LoginNavbar is re-used here
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          '',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background for consistency
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Adjusted padding
          child: Container(
            padding: const EdgeInsets.all(30), // Increased inner padding for better spacing
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, // Use themed card color (white)
              //borderRadius: Theme.of(context).cardTheme.shape?.borderRadius, // Use themed card border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Create Your Vet Account", // More engaging title
                    style: textTheme.headlineSmall?.copyWith(
                      //color: kPrimaryGreen, // Themed title color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Join our platform to manage your practice efficiently.", // Informative subtitle
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress, // Added keyboard type
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: kAccentGreen), // Themed icon
                      // Border and focusedBorder are handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20), // Consistent spacing
                  TextFormField(
                    controller: usernameController,
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: kAccentGreen), // Themed icon
                      // Border and focusedBorder are handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 20), // Consistent spacing
                  TextFormField(
                    controller: passwordController,
                    obscureText: true, // Retained original obscureText functionality
                    style: textTheme.bodyLarge, // Use themed text style for input
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: kAccentGreen), // Themed icon
                      // Border and focusedBorder are handled by InputDecorationTheme in main.dart
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.greenAccent)) // Themed loading indicator
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: register,
                      // Button styling is handled by ElevatedButtonThemeData in main.dart
                      child: Text(
                        "Register",
                        style: textTheme.labelLarge, // Use themed labelLarge for button text
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 20), // Increased space for message
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: message!.toLowerCase().contains('success') ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: textTheme.bodyMedium, // Use themed text style
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VetLoginPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kAccentGreen, // Use accent green for login link
                        ),
                        child: Text(
                          'Login',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}