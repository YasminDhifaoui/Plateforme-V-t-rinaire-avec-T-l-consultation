import 'dart:convert';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;
import '../auth_services/token_service.dart';

class AnimalUpdateService {
  final String baseUrl = '${BaseUrl.api}/api/client/AnimalsC';

  Future<void> updateAnimal({
    required String id,
    required String name,
    required int age,
    String? allergies,
    String? antecedentsmedicaux,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('No authentication token found.');
    }

    final body = json.encode({
      'Name': name,
      'Age': age,
      'Allergies': allergies ?? '',
      'AntecedentsMedicaux': antecedentsmedicaux ?? '',
    });

    final response = await http.put(
      Uri.parse('$baseUrl/update-animal/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update animal: ${response.statusCode}');
    }
  }
}
