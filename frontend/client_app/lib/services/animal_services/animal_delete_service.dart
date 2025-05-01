import 'package:http/http.dart' as http;
import '../auth_services/token_service.dart';

class AnimalDeleteService {
  final String baseUrl = 'http://10.0.2.2:5000/api/client/AnimalsC';

  Future<void> deleteAnimal(String id) async {
    final token = await TokenService.getToken();
    print("$token");
    if (token == null) {
      throw Exception('No authentication token found.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/delete-animal/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete animal: ${response.statusCode}');
    }
  }
}
