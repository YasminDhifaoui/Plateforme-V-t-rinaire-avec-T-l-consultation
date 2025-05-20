import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/utils/base_url.dart';

class AnimalsVetService {
  static final String baseUrl = "${BaseUrl.api}/api/veterinaire/AnimalsVet";

  // Existing method
  Future<List<AnimalModel>> getAnimalsList(String token) async {
    final url = Uri.parse("$baseUrl/animals-list");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('AnimalsVetService response status: ${response.statusCode}');
    print('AnimalsVetService response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AnimalModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
        'Failed to load animals: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ✅ New method for getting animals by client ID
  Future<List<AnimalModel>> getAnimalsByClientId(
    String token,
    String clientId,
  ) async {
    final url = Uri.parse("$baseUrl/client/$clientId");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('getAnimalsByClientId response status: ${response.statusCode}');
    print('getAnimalsByClientId response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AnimalModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
        'Failed to load client animals: ${response.statusCode} ${response.body}',
      );
    }
  }
}
