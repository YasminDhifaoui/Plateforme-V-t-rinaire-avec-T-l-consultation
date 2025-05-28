import 'package:flutter/material.dart';
import 'package:veterinary_app/main.dart'; // For kPrimaryGreen, kAccentGreen
import 'package:veterinary_app/services/auth_services/token_service.dart';


import '../../models/profile_models/VetChangePasswordModel.dart'; // <--- Check this path and class name
import '../../services/profile_services/change_pass_service.dart'; // <--- Correct service import

class VetChangePasswordPage extends StatefulWidget {
  const VetChangePasswordPage({super.key});

  @override
  State<VetChangePasswordPage> createState() => _VetChangePasswordPageState();
}

class _VetChangePasswordPageState extends State<VetChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  final changePassService _apiService = changePassService();

  bool isLoading = false;
  String responseMessage = '';
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Add more complexity rules if needed (e.g., regex for uppercase, lowercase, numbers, symbols)
    return null;
  }

  String? _validateConfirmNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

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

  void _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    try {
      // Use the TokenService to retrieve the JWT token
      final String? jwtToken = await TokenService.getToken(); // <--- Corrected line

      if (jwtToken == null) {
        _showSnackBar('Authentication token not found. Please log in again.', isSuccess: false);
        // It's good practice to navigate the user back to the login page if their session is invalid
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => const VetLoginPage()), // Assuming you have a VetLoginPage
        //   (Route<dynamic> route) => false,
        // );
        return;
      }

      final model = VetChangePasswordDto(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmPassword: confirmNewPasswordController.text.trim(),
      );

      final result = await _apiService.changeVetPassword(model, jwtToken);

      setState(() {
        responseMessage = result["message"] ?? "Unknown response";
      });

      if (result["success"] == true) {
        _showSnackBar(responseMessage, isSuccess: true);
        // Optionally clear fields or navigate back after success
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmNewPasswordController.clear();
        // You might want to pop this page after successful change
        // Navigator.pop(context);
      } else {
        _showSnackBar(responseMessage, isSuccess: false);
      }
    } catch (e, stacktrace) {
      setState(() {
        responseMessage = 'An error occurred: ${e.toString()}';
      });
      _showSnackBar(responseMessage, isSuccess: false);
      print('Change password error: $e');
      print('Stacktrace: $stacktrace');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(15),
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
                    Icons.lock_open_rounded,
                    size: 70,
                    color: kPrimaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Your Password',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your current password and then set your new password.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: kAccentGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: _validateCurrentPassword,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: _obscureNewPassword,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_open_rounded, color: kAccentGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmNewPasswordController,
                    obscureText: _obscureConfirmNewPassword,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: kAccentGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: _validateConfirmNewPassword,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitChangePassword,
                      icon: const Icon(Icons.security_update_rounded, color: Colors.white),
                      label: Text(
                        'Change Password',
                        style: textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                  if (responseMessage.isNotEmpty && !responseMessage.toLowerCase().contains('success'))
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        responseMessage,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
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