import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileService {
  final String editProfileUrl;

  EditProfileService({required this.editProfileUrl});

  Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
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
      return {'success': true};
    } else {
      String errorMessage = 'Failed to update profile. Please try again.';
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('message')) {
          errorMessage = responseBody['message'];
        }
      } catch (e) {
        // ignore JSON parse errors
      }
      return {'success': false, 'error': errorMessage};
    }
  }
}
