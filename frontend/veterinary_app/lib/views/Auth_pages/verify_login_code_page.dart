import 'package:flutter/material.dart';
import 'package:veterinary_app/models/auth_models/vet_verify_login.dart';
import 'package:veterinary_app/services/auth_services/vet_auth_services.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import '../../utils/app_colors.dart'; // Correct: Import for kPrimaryGreen, kAccentGreen
import '../home_page.dart'; // Still needed as you navigate to it from here

class VerifyLoginCodePage extends StatefulWidget {
  final String email;
  final Function(String token)? onLoginSuccessCallback;

  const VerifyLoginCodePage({
    super.key,
    required this.email,
    this.onLoginSuccessCallback,
  });

  @override
  State<VerifyLoginCodePage> createState() => _VerifyLoginCodePageState();
}

class _VerifyLoginCodePageState extends State<VerifyLoginCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final ApiService _apiService = ApiService();

  String responseMessage = '';
  bool isLoading = false;

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    try {
      final verifyDto = VetVerifyLoginDto(
        email: widget.email,
        code: codeController.text.trim(),
      );

      final result = await _apiService.verifyLoginCode(verifyDto);

      // --- CRUCIAL DEBUG PRINT ---
      print('API Verification Result Full: $result');
      // --- END CRUCIAL DEBUG PRINT ---

      if (result['success'] == true && result['data'] != null) {
        final data = result['data']; // This 'data' is the outer map returned by the API
        final token = data['token'] as String? ?? ''; // Safely cast and default to empty string

        // This 'data' is expected to be the nested 'data' map containing user info
        final userData = data['data'] as Map<String, dynamic>?;

        // Safely access username and userId from the nested userData map
        final username = userData?['username'] as String? ?? '';
        final userId = userData?['userId'] as String? ?? '';

        print('Extracted Token: "$token"');
        print('Extracted User ID: "$userId"');
        print('Extracted Username: "$username"');



        await _storeSession(token, userId, username);

        widget.onLoginSuccessCallback?.call(token);

        if (mounted) {
          _showSnackBar('Verification successful! Welcome, $username.', isSuccess: true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: username, token: token),
            ),
          );
        }
      } else {
        setState(() {
          responseMessage = result['message'] ?? 'Verification failed.';
        });
        _showSnackBar(responseMessage, isSuccess: false);
      }
    } catch (e) {
      setState(() {
        responseMessage = 'An error occurred: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _storeSession(String token, String userId, String username) async {
    await TokenService.saveToken(token, userId, username);
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  Icon(
                    Icons.verified_user_rounded,
                    size: 70,
                    color: kPrimaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Two-Factor Verification',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please enter the 6-digit code sent to:',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  Text(
                    widget.email,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 5.0),
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade400),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Verification code is required';
                      }
                      if (value.length < 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                        : ElevatedButton.icon(
                      onPressed: verifyCode,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: Text(
                        'Verify',
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (responseMessage.isNotEmpty)
                    Text(
                      responseMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: responseMessage.toLowerCase().contains('success')
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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