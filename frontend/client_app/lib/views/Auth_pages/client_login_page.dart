import 'package:client_app/models/auth_models/client_login.dart';
import 'package:client_app/services/auth_services/client_auth_services.dart';
import 'package:client_app/views/Auth_pages/client_register_page.dart';
import 'package:client_app/views/components/login_navbar.dart'; // Keep this import if LoginNavbar is custom and needed elsewhere
import 'package:client_app/views/Auth_pages/verify_login_code_page.dart'; // Corrected import for VerifyLoginCodePage
import 'package:client_app/views/Auth_pages/client_forgot_password_page.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

// Import the blue color constants from main.dart
import 'package:client_app/main.dart'; // Assuming main.dart holds kPrimaryBlue, kAccentBlue etc.

class ClientLoginPage extends StatefulWidget {
  // CORRECTED: This signature is now consistent with main.dart and VerifyLoginCodePage
  final Function(String token, String userId, String username)? onLoginSuccessCallback;

  const ClientLoginPage({super.key, this.onLoginSuccessCallback});

  @override
  State<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _authService = ApiService();
  bool _obscurePassword = true; // For password visibility toggle


  String responseMessage = '';
  bool isLoading = false;

  void loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

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
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyLoginCodePage(
                email: emailController.text.trim(),
                // This line is CORRECT! It passes the callback down.
                onLoginSuccessCallback: widget.onLoginSuccessCallback,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
    // Access the defined text theme
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kPrimaryBlue, // Explicitly use our primary blue
        elevation: 0,
        leading: IconButton( // Add a back button for navigation
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Padding around the scrollable content
          child: Card( // Using Card for a subtle elevation and professional look
            elevation: 8, // Add a shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners for the card
            ),
            margin: EdgeInsets.zero, // Card handles its own margin via parent padding
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Padding inside the card
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Keep column compact
                  children: [
                    Text(
                      "Welcome Back!",
                      style: textTheme.headlineMedium?.copyWith(
                        color: kPrimaryBlue, // Use primary blue for the title
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Login to access your pet's healthcare portal.",
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
                        prefixIcon: const Icon(Icons.email, color: kAccentBlue), // Blue icon
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded input field borders
                          borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2), // Stronger blue on focus
                        ),
                        errorBorder: OutlineInputBorder( // Style for validation error
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder( // Style for validation error when focused
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        labelStyle: textTheme.bodyMedium,
                        hintStyle: textTheme.bodySmall?.copyWith(color: Colors.black38),
                      ),
                      validator: _validateEmail,
                      style: textTheme.bodyLarge, // Text input style
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword, // <--- CORRECTED: Use the state variable here
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "********",
                        prefixIcon: const Icon(Icons.lock, color: kAccentBlue), // Blue icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClientForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot password?",
                          style: textTheme.bodyMedium?.copyWith(
                            color: kPrimaryBlue, // Blue text for links
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: isLoading
                          ? CircularProgressIndicator(color: kPrimaryBlue) // Blue loading indicator
                          : ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue, // Use primary blue for button
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded button corners
                          ),
                          elevation: 5, // Add a subtle shadow
                        ),
                        child: Text("Login", style: textTheme.labelLarge),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (responseMessage.isNotEmpty)
                      Text(
                        responseMessage,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: responseMessage.toLowerCase().contains('success') ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientRegisterPage(), // Corrected to ClientRegisterPage
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up", // Changed text to "Sign Up" for common usage
                            style: textTheme.bodyMedium?.copyWith(
                              color: kPrimaryBlue, // Blue text for link
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