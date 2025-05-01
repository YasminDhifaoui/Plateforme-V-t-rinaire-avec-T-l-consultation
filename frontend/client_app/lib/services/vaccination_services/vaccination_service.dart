import 'dart:convert';
import 'package:client_app/models/vaccination_models/vaccination.dart';
import 'package:http/http.dart' as http;
import 'package:client_app/services/auth_services/token_service.dart';

class VaccinationService {
  final String baseUrl = 'http://10.0.2.2:5000/api/client/VaccinationC';

  Future<List<Vaccination>> getVaccinationsForAnimal(String animalId) async {
    final token = await TokenService.getToken();

    if (token == null) {
      throw Exception('JWT token is null. User might not be authenticated.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/get-vaccinations-per-animalId/$animalId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Vaccination.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load vaccinations. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
