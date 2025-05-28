import 'dart:convert'; // Not strictly needed for this simple DTO, but good practice

class ClientChangePasswordDto {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ClientChangePasswordDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}