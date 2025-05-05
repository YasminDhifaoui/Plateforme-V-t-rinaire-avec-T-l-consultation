import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/vaccination_models/vaccination_model.dart';

class VaccinationService {
  static const String baseUrl =
      "http://10.0.2.2:5000/api/veterinaire/VaccinationsVet";

  Future<List<VaccinationModel>> getAllVaccinations(String token) async {
    final url = Uri.parse("$baseUrl/get-all-vaccinations");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => VaccinationModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
        'Failed to load vaccinations: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<VaccinationModel>> getVaccinationsByAnimalId(
    String token,
    String animalId,
  ) async {
    final url = Uri.parse("$baseUrl/get-vaccinations-by-animal/$animalId");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => VaccinationModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
        'Failed to load vaccinations by animal: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> addVaccination(String token, Map<String, dynamic> dto) async {
    final url = Uri.parse("$baseUrl/add-vaccination");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(dto),
    );

    if (response.statusCode == 200) {
      // Assuming success response is plain text or no content
      return true;
    } else {
      throw Exception(
        'Failed to add vaccination: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> updateVaccination(
    String token,
    String id,
    Map<String, dynamic> dto,
  ) async {
    final url = Uri.parse("$baseUrl/update-vaccination/$id");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(dto),
    );

    if (response.statusCode == 200) {
      // Assuming success response is plain text or no content
      return true;
    } else {
      throw Exception(
        'Failed to update vaccination: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> deleteVaccination(String token, String id) async {
    final url = Uri.parse("$baseUrl/delete-vaccination/$id");

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to delete vaccination: ${response.statusCode} ${response.body}',
      );
    }
  }
}
