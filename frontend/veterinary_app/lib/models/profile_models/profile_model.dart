class ProfileModel {
  final String email;
  final String userName;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String address;
  final String zipCode;
  final String gender;
  final List<String> animalNames;

  ProfileModel({
    required this.email,
    required this.userName,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.address,
    required this.zipCode,
    required this.gender,
    required this.animalNames,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      birthDate: json['birthDate'] ?? '',
      address: json['address'] ?? '',
      zipCode: json['zipCode'] ?? '',
      gender: json['gender'] ?? '',
      animalNames: List<String>.from(json['animalNames'] ?? []),
    );
  }
}
