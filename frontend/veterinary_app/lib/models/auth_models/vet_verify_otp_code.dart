// veterinary_app/models/auth_models/vet_verify_otp_code.dart
import 'dart:convert';

class VetVerifyOtpCodeDto {
  final String email;
  final String otpCode;

  VetVerifyOtpCodeDto({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otpCode': otpCode,
    };
  }
}