import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/animal.dart';
import '../token_service.dart';

class AnimalService {
  final String baseUrl = 'http://10.0.2.2:5000/api/client/animalsc';

  Future<List<Animal>> getAnimalsList() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('No authentication token found.');
    }

    final response = await http.get(
      Uri.parse('\$baseUrl/animals-list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Animal.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token.');
    } else {
      throw Exception('Failed to load animals list: \${response.statusCode}');
    }
  }
}
