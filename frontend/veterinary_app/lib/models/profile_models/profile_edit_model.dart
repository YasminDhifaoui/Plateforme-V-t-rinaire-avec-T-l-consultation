class ProfileEditModel {
  final String userName;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthDate;
  final String address;
  final String zipCode;
  final String gender;
  final String email; // Add the email field here

  ProfileEditModel({
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthDate,
    required this.address,
    required this.zipCode,
    required this.gender,
    required this.email,
  });

  // Convert the ProfileEditModel to a Map (for API requests)
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'address': address,
      'zipCode': zipCode,
      'gender': gender,
      'email': email,
    };
  }

  // Convert a Map to a ProfileEditModel instance
  factory ProfileEditModel.fromMap(Map<String, dynamic> map) {
    return ProfileEditModel(
      userName: map['userName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      birthDate: map['birthDate'],
      address: map['address'],
      zipCode: map['zipCode'],
      gender: map['gender'],
      email: map['email'],
    );
  }
}
