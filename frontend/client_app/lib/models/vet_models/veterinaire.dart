class Veterinaire {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String firstName;
  final String lastName;

  Veterinaire({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.firstName,
    required this.lastName,
  });

  factory Veterinaire.fromJson(Map<String, dynamic> json) {
    return Veterinaire(
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }
}
