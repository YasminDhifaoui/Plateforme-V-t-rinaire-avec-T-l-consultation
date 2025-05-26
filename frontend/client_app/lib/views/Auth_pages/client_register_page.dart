import 'package:client_app/models/auth_models/client_register.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:client_app/views/Auth_pages/client_confirm_email_page.dart';
import 'package:client_app/views/Auth_pages/client_login_page.dart';
import 'package:client_app/views/components/login_navbar.dart'; // Keep if it's a custom widget, otherwise AppBar is fine
import 'package:flutter/material.dart';

// Import the blue color constants from main.dart
import 'package:client_app/main.dart'; // Assuming main.dart holds kPrimaryBlue, kAccentBlue etc.

class ClientRegisterPage extends StatefulWidget { // Renamed from RegisterPage for consistency
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState(); // Renamed state class
}

class _ClientRegisterPageState extends State<ClientRegisterPage> { // Renamed state class
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isLoading = false;
  String? message;

  void register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
      message = null;
    });

    final client = ClientRegister(
      email: emailController.text,
      username: usernameController.text,
      password: passwordController.text,
    );

    try {
      final result = await apiService.registerClient(client);

      setState(() {
        isLoading = false;
        message = result["message"];
      });

      if (result["success"]) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Registration successful! Please check your email to confirm.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600, // Green for success
              behavior: SnackBarBehavior.floating, // Modern snackbar style
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );

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
      } else {
        // If registration was not successful, ensure message is displayed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message ?? "Registration failed. Please try again.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600, // Red for error
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Registration failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration failed: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
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

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    // Optional: Add more username validation rules (e.g., min length, no special chars)
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Optional: Add more password complexity rules (e.g., contains uppercase, number, special char)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Create Your Account",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Join our community for seamless pet care services.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "example@email.com",
                        prefixIcon: const Icon(Icons.email, color: kAccentBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        labelStyle: textTheme.bodyMedium,
                        hintStyle: textTheme.bodySmall?.copyWith(color: Colors.black38),
                      ),
                      validator: _validateEmail,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Username",
                        hintText: "petlover123",
                        prefixIcon: const Icon(Icons.person, color: kAccentBlue), // Icon for username
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        labelStyle: textTheme.bodyMedium,
                        hintStyle: textTheme.bodySmall?.copyWith(color: Colors.black38),
                      ),
                      validator: _validateUsername,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "********",
                        prefixIcon: const Icon(Icons.lock, color: kAccentBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        labelStyle: textTheme.bodyMedium,
                        hintStyle: textTheme.bodySmall?.copyWith(color: Colors.black38),
                      ),
                      validator: _validatePassword,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: isLoading
                          ? CircularProgressIndicator(color: kPrimaryBlue)
                          : ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text("Register", style: textTheme.labelLarge),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Displaying API response message if any
                    if (message != null && !isLoading) // Only show message if not loading
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: message!.toLowerCase().contains('success') ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientLoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: textTheme.bodyMedium?.copyWith(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}