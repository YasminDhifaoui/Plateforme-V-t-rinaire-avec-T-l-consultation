// lib/models/auth_models/client_reset_password.dart
import 'dart:convert';

class ClientResetPasswordDto {
  final String email;
  final String newPassword;
  final String confirmPassword; // Must match backend DTO field name

  ClientResetPasswordDto({
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}