import 'dart:convert';
import 'package:client_app/services/auth_services/token_service.dart';
import 'package:http/http.dart' as http;

class AddRendezvousService {
  final String baseUrl = "http://10.0.2.2:5000/api/client/rendez_vousc";

  Future<void> addRendezvous(Map<String, dynamic> data) async {
    final token = await TokenService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/add-rendez-vous'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add rendezvous');
    }
  }
}
