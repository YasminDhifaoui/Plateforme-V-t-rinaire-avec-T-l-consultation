class ClientVerifyLoginDto {
  final String email;
  final String code;

  ClientVerifyLoginDto({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}
