import 'dart:convert';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;
import '../auth_services/token_service.dart';

class AnimalAddService {
  final String baseUrl = '${BaseUrl.api}/api/client/AnimalsC';

  Future<void> addAnimal({
    required String name,
    required String espece,
    required String race,
    required int age,
    required String sexe,
    String? allergies,
    String? antecedentsmedicaux,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('No authentication token found.');
    }

    final body = json.encode({
      'Name': name,
      'Espece': espece,
      'Race': race,
      'Age': age,
      'Sexe': sexe,
      'Allergies': allergies ?? '',
      'AntecedentsMedicaux': antecedentsmedicaux ?? '',
    });

    final response = await http.post(
      Uri.parse('$baseUrl/add-animal'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add animal: ${response.statusCode}');
    }
  }
}
