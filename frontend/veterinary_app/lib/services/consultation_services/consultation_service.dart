import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';

class ConsultationService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  static const String _getEndpoint =
      '$_baseUrl/api/vet/consultationsvet/get-consultations';

  // Headers used in all requests
  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET consultations
  static Future<List<Consultation>> fetchConsultations(String token) async {
    final response = await http.get(
      Uri.parse(_getEndpoint),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((item) => Consultation.fromJson(item)).toList();
    } else {
      print('Failed: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load consultations');
    }
  }

  /// POST create consultation (using multipart if uploading file)
  static Future<void> createConsultation(
    Map<String, String> fields,
    String token,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/vet/consultationsvet/create-consultation',
    );

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(token));
    request.fields.addAll(fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Failed to create consultation');
    }
  }

  /// PUT update consultation
  static Future<void> updateConsultation(
    String id,
    Map<String, String> fields,
    String token,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/vet/consultationsvet/update-consultation/$id',
    );

    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(_headers(token));
    request.fields.addAll(fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Failed to update consultation');
    }
  }

  /// DELETE consultation
  static Future<void> deleteConsultation(String id, String token) async {
    final uri = Uri.parse(
      '$_baseUrl/api/vet/consultationsvet/delete-consultation/$id',
    );

    final response = await http.delete(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Failed to delete consultation');
    }
  }
}
