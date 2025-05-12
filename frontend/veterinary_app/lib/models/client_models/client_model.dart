class ClientModel {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String address;

  ClientModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: int.tryParse(json['id'].toString()) ?? 0, // Safe parsing
      username: json['userName'] ?? json['username'] ?? "",
      email: json['email'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      address: json['address'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'username': username ?? '',
      'email': email ?? '',
      'phoneNumber': phoneNumber ?? '',
      'address': address?? '',
    };
  }
}
