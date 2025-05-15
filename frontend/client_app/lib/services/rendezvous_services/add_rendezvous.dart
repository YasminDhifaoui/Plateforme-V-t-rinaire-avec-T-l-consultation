import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client_app/services/auth_services/token_service.dart';

class AddRendezvousService {
  // Updated baseUrl
  final String baseUrl = "http://10.0.2.2:5000/api/client";  // Keep base URL without endpoint path

  Future<void> addRendezvous(Map<String, dynamic> data) async {
    final token = await TokenService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/Rendez_vousC/add-rendez-vous'),  // Correctly appending the full path
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // If request is successful
      print('Rendez-vous added successfully');
    } else {
      // If request fails, throw an error
      throw Exception('Failed to add rendezvous: ${response.body}');
    }
  }
}
