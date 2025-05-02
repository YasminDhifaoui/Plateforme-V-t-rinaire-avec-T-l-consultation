class ClientModel {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;

  ClientModel({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      username: json['username']?? "",
      email: json['email']?? "",
      phoneNumber: json['phoneNumber']?? "",
      address: json['address']?? "",
    );
  }
}
