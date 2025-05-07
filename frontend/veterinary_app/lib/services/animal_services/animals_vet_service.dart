import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/animal_models/animal_model.dart';

class AnimalsVetService {
  static const String baseUrl =
      "http://10.0.2.2:5000/api/veterinaire/AnimalsVet";

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
      // No animals found for this veterinarian
      return [];
    } else {
      throw Exception(
        'Failed to load animals: ${response.statusCode} ${response.body}',
      );
    }
  }
}
