// services/conv_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/conv_models/conv_model.dart';
import '../auth_services/token_service.dart';

class ConvService {
  final String baseUrl = 'http://10.0.2.2:5000/api/conv';

  Future<List<Conversation>> getConversations() async {
    final token = await TokenService.getToken();

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Conversation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }
}
