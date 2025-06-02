
class VetChangePasswordDto {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  VetChangePasswordDto({
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