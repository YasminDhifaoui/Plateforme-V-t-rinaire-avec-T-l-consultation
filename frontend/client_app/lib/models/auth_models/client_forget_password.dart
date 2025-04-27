class ClientForgetPasswordDto {
  final String email;

  ClientForgetPasswordDto({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
