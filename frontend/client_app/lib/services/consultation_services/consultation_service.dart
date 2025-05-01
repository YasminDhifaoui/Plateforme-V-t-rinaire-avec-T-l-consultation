import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/consultation_models/consultation.dart';
import '../auth_services/token_service.dart';

class ConsultationService {
  final String baseUrl = 'http://10.0.2.2:5000/api/client/ConsultationsC';

  Future<List<Consultation>> getConsultationsList() async {
    final token = await TokenService.getToken();

    if (token == null) {
      throw Exception('No authentication token found.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/my-consultations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Consultation.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token.');
    } else {
      throw Exception(
          "Failed to load consultations list: ${response.statusCode}");
    }
  }
}
