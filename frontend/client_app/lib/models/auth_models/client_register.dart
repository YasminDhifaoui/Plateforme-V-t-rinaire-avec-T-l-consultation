class ClientRegister {
  final String email;
  final String username;
  final String password;

  ClientRegister({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'username': username, 'password': password};
  }
}
