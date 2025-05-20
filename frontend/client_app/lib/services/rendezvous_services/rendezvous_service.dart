import 'dart:convert';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:client_app/models/rendezvous_models/rendezvous.dart';
import 'package:client_app/services/auth_services/token_service.dart';

class RendezvousService {
  static final String _baseUrl = '${BaseUrl.api}/api/client/rendez_vousC';

  /// Fetches a list of rendezvous (appointments) for the current client.
  Future<List<Rendezvous>> getRendezvousList() async {
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('JWT token is missing. Please log in again.');
    }

    final uri = Uri.parse('$_baseUrl/rendez-vous-list');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((e) => Rendezvous.fromJson(e)).toList();
      } catch (e) {
        throw Exception('Error parsing rendezvous data: $e');
      }
    } else {
      throw Exception(
        'Failed to load rendezvous.\n'
        'Status Code: ${response.statusCode}\n'
        'Response Body: ${response.body}',
      );
    }
  }
}
