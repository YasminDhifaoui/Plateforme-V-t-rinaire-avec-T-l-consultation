import 'dart:convert';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;

class AnimalService {
  final String baseUrl = "${BaseUrl.api}/api/client/animalsc";

  Future<List<Animal>> getAnimalsList() async {
    final token = await TokenService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/animals-list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Animal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load animals');
    }
  }
}
