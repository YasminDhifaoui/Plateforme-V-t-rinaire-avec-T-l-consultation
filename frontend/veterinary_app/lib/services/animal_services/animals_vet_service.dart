import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/utils/base_url.dart';

import '../../models/animal_models/update_animal_vet_dto.dart';

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

  Future<Map<String, dynamic>> updateAnimal(
      String animalId, UpdateAnimalVetDto model, String jwtToken) async {
    final url = Uri.parse("$baseUrl/update-animal/$animalId"); // Construct URL with animal ID

    print('Attempting to update animal: $animalId');
    print('URL: $url');
    print('Headers: {"Content-Type": "application/json", "Authorization": "Bearer $jwtToken"}');
    print('Body: ${jsonEncode(model.toJson())}');

    try {
      final response = await http
          .put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode(model.toJson()),
      )
          .timeout(const Duration(seconds: 15));

      print('Response Status Code: ${response.statusCode}');
      print('Raw Response Body: "${response.body}"');

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server, check backend logs."};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"] ?? "Animal updated successfully."};
      } else if (response.statusCode == 404) {
        return {"success": false, "message": data["message"] ?? "Animal or Vet not found."};
      } else if (response.statusCode == 400) {
        return {"success": false, "message": data["message"] ?? "Bad request, check input data."};
      }
      else {
        return {"success": false, "message": data["message"] ?? "Failed to update animal."};
      }
    } catch (e, stacktrace) {
      print('Exception during updateAnimal: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }
}
