import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/rendezvous_models/rendezvous_model.dart';
import 'package:veterinary_app/utils/base_url.dart';

class RendezVousService {
  final String baseUrl = '${BaseUrl.api}/api/veterinaire/RendezVousVet';

  Future<List<RendezVousModel>> getRendezVousList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rendez-vous-list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((item) => RendezVousModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load rendez-vous');
    }
  }

  Future<void> updateRendezVousStatus(
    String token,
    String rendezVousId,
    int newStatus, // 👈 Change to int
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update-status/$rendezVousId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(newStatus), // 👈 Send plain number (no object)
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }
}
