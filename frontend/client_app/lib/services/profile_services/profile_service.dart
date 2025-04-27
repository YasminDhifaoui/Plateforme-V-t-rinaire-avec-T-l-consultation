import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/profile_models/profile_model.dart';

class ProfileService {
  final String profileUrl;

  ProfileService({required this.profileUrl});

  Future<ProfileModel> fetchProfile(String token) async {
    final url = Uri.parse(profileUrl);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse =
          json.decode(response.body) as Map<String, dynamic>;
      return ProfileModel.fromJson(jsonResponse);
    } else {
      print(
          'ProfileService.fetchProfile failed with status: \${response.statusCode}');
      print('Response body: \${response.body}');
      throw Exception(
          'Failed to load profile: \${response.statusCode} \${response.body}');
    }
  }
}
