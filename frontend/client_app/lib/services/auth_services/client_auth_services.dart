import 'dart:convert';
import 'package:client_app/models/auth_models/client_confirm_email.dart';
import 'package:http/http.dart' as http;
import '../../models/auth_models/client_register.dart';
import '../../models/auth_models/client_login.dart';
import '../../models/auth_models/client_verify_login.dart';

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

      print('Raw response body: ${response.body}'); // Added for debugging
      print('Response headers: ${response.headers}'); // Added for debugging

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      if (response.headers['content-type'] == null ||
          !response.headers['content-type']!.contains('application/json')) {
        print('Unexpected content-type: ${response.headers['content-type']}');
        return {"success": false, "message": "Unexpected response format"};
      }

      try {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Registration failed.";
        if (response.statusCode == 200) {
          return {"success": true, "message": message};
        } else {
          return {"success": false, "message": message};
        }
      } catch (jsonError) {
        print('JSON decode error: $jsonError');
        return {"success": false, "message": "Invalid response format"};
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
          .timeout(const Duration(seconds: 20));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {"success": false, "message": data["message"] ?? "Login failed"};
      }
    } catch (e, stacktrace) {
      print('Error during loginClient: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

  // confirm email
  Future<Map<String, dynamic>> ConfirmEmail(
    ClientConfirmEmailDto confirmDto,
  ) async {
    final url = Uri.parse(
      "$baseUrl/confirm-client-email?email=${Uri.encodeComponent(confirmDto.email)}&code=${Uri.encodeComponent(confirmDto.code)}",
    );

    try {
      final response = await http.post(url, headers: {
        "Content-Type": "application/json"
      }).timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Verification code is wrong or expired",
        };
      }
    } catch (e, stacktrace) {
      print('Error during email confirmation: $e');
      print('stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// Verify 2FA login code
  Future<Map<String, dynamic>> verifyLoginCode(
      ClientVerifyLoginDto verifyDto) async {
    final url = Uri.parse("$baseUrl/verify-login-code");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(verifyDto.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Verification failed"
        };
      }
    } catch (e, stacktrace) {
      print('Error during verifyLoginCode: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }
}
