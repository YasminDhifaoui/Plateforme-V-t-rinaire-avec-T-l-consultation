import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_register.dart';
import '../models/client_login.dart';

class ApiService {
  static const String baseUrl =
      "http://10.0.2.2:5000/api/ClientAuthentification";

  /// Register a new client
  Future<Map<String, dynamic>> registerClient(ClientRegister client) async {
    final url = Uri.parse("$baseUrl/register");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(client.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Registration failed.",
        };
      }
    } catch (e, stacktrace) {
      print('Error during registerClient: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// Login existing client
  Future<Map<String, dynamic>> loginClient(ClientLoginDto loginDto) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(loginDto.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Login failed.",
        };
      }
    } catch (e, stacktrace) {
      print('Error during loginClient: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }
}
