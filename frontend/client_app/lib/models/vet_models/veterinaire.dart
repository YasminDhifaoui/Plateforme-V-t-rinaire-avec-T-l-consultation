class Veterinaire {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;

  Veterinaire({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
  });

  factory Veterinaire.fromJson(Map<String, dynamic> json) {
    return Veterinaire(
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
    );
  }
}
