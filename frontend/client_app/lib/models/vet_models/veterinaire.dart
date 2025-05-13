class Veterinaire {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String firstName;
  final String lastName;

  Veterinaire({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.firstName,
    required this.lastName,
  });

  factory Veterinaire.fromJson(Map<String, dynamic> json) {
    return Veterinaire(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return '$firstName $lastName'; // Useful for debugging or dropdown display
  }
}
