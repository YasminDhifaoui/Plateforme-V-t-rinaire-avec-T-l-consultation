import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/client_models/client_model.dart';

class ClientService {
  final String baseUrl = 'http://10.0.2.2:5000/api/veterinaire/clientvet';

  Future<List<ClientModel>> getAllClients(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-all-clients'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ClientModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch clients');
    }
  }
}
