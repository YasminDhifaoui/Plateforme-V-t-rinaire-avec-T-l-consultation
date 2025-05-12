import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/vet_models/veterinaire.dart';

import '../auth_services/token_service.dart'; // Import the TokenService

class VeterinaireService {
  // Define the base URL for your API
  final url = Uri.parse(
    "http://10.0.2.2:5000/api/client/VetsC/get-all-veterinaires",
  );

  Future<List<Veterinaire>> getAllVeterinaires() async {
    try {
      // Retrieve the JWT token from TokenService
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception("Authorization token is missing.");
      }

      // Set up headers including the Authorization token
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Make the API call with the headers containing the token
      final response = await http.get(url, headers: headers);

      // Print status code and response body for debugging
      print("Status code: ${response.statusCode}");
      print("Body: ${response.body}");

      // If the request is successful, parse the response body
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Veterinaire.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load veterinaires');
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}
