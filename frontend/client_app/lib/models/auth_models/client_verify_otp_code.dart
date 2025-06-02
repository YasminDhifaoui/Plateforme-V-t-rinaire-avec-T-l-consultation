// lib/models/auth_models/client_verify_otp_code.dart

class ClientVerifyOtpCodeDto {
  final String email;
  final String otpCode;

  ClientVerifyOtpCodeDto({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otpCode': otpCode,
    };
  }
}