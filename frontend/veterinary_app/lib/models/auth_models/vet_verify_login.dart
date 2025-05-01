class VetVerifyLoginDto {
  final String email;
  final String code;

  VetVerifyLoginDto({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}
