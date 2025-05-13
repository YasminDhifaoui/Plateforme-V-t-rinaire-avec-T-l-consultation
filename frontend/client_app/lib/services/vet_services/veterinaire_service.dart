import 'dart:convert';
import 'package:client_app/models/vet_models/veterinaire.dart';
import 'package:client_app/services/auth_services/token_service.dart';
import 'package:http/http.dart' as http;

class VeterinaireService {
  final String baseUrl = "http://10.0.2.2:5000/api/client/vetsc/get-all-veterinaires";

  Future<List<Veterinaire>> getAllVeterinaires() async {
    final token = await TokenService.getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Veterinaire.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load veterinaires');
    }
  }
}
