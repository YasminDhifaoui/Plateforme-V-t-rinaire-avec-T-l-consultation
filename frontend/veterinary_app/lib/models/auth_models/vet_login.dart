class VetLoginDto {
  final String email;
  final String password;

  VetLoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
