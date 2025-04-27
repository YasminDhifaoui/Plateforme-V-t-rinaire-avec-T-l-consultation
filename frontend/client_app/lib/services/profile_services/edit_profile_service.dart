import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileService {
  final String editProfileUrl;

  EditProfileService({required this.editProfileUrl});

  Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(editProfileUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    print('Update profile response status: ${response.statusCode}');
    print('Update profile response body: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
