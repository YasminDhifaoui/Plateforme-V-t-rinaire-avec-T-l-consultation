import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:http/http.dart' as http;

class DeleteRendezvousService {
  final String baseUrl = "${BaseUrl.api}/api/client/rendez_vousc";

  Future<void> deleteRendezvous(String id) async {
    final token = await TokenService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-rendez-vous/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete rendezvous');
    }
  }
}
