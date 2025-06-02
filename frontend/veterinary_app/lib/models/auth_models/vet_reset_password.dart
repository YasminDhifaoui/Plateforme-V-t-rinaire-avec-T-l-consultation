// veterinary_app/models/auth_models/vet_reset_password.dart

class VetResetPasswordDto {
  final String email;
  final String newPassword;
  final String confirmPassword; // Must match backend DTO field name

  VetResetPasswordDto({
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