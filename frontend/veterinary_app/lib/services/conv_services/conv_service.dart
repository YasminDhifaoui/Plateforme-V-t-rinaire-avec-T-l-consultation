// services/conv_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/utils/base_url.dart';

import '../../models/conv_models/conv_model.dart';

class ConvService {
  final String baseUrl = '${BaseUrl.api}/api/conv';

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
