class VetConfirmEmailDto {
  final String email;
  final String code;

  VetConfirmEmailDto({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }

  factory VetConfirmEmailDto.fromJson(Map<String, dynamic> json) {
    return VetConfirmEmailDto(
      email: json['email'] ?? '',
      code: json['code'] ?? '',
    );
  }
}
