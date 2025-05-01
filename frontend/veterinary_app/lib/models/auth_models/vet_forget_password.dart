class VetForgetPasswordDto {
  final String email;

  VetForgetPasswordDto({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
