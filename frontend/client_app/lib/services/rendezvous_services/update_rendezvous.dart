import 'dart:convert';
import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;

class UpdateRendezvousService {
  final String baseUrl = "${BaseUrl.api}/api/client/rendez_vousc";

  Future<void> updateRendezvous(String id, Map<String, dynamic> data) async {
    final token = await TokenService.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/update-rendez-vous/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      // You can print response.body to get more context on error
      throw Exception(
          'Échec de la mise à jour du rendez-vous: ${response.body}');
    }
  }
}
