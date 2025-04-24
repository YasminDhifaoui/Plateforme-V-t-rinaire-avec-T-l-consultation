class ClientConfirmEmailDto {
  final String email;
  final String code;

  ClientConfirmEmailDto({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }

  factory ClientConfirmEmailDto.fromJson(Map<String, dynamic> json) {
    return ClientConfirmEmailDto(
      email: json['email'] ?? '',
      code: json['code'] ?? '',
    );
  }
}
