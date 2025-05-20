import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/auth_models/vet_confirm_email.dart';
import 'package:veterinary_app/models/auth_models/vet_forget_password.dart';
import 'package:veterinary_app/models/auth_models/vet_verify_login.dart';
import 'package:veterinary_app/utils/base_url.dart';

import '../../models/auth_models/vet_register.dart';
import '../../models/auth_models/vet_login.dart';

class ApiService {
  static final String baseUrl = "${BaseUrl.api}/api/VetAuthentification";

  /// Register a new client
  Future<Map<String, dynamic>> registerClient(VetRegister vet) async {
    final url = Uri.parse("$baseUrl/register");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(vet.toJson()),
          )
          .timeout(const Duration(seconds: 10));

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
  Future<Map<String, dynamic>> loginClient(VetLoginDto loginDto) async {
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
      return {"success": false, "message": "Error: $e $stacktrace"};
    }
  }

  // confirm email
  Future<Map<String, dynamic>> ConfirmEmail(
    VetConfirmEmailDto confirmDto,
  ) async {
    final url = Uri.parse(
      "$baseUrl/confirm-veterinaire-email?email=${Uri.encodeComponent(confirmDto.email)}&code=${Uri.encodeComponent(confirmDto.code)}",
    );

    try {
      final response = await http
          .post(url, headers: {"Content-Type": "application/json"})
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
    VetVerifyLoginDto verifyDto,
  ) async {
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
          "message": data["message"] ?? "Verification failed",
        };
      }
    } catch (e, stacktrace) {
      print('Error during verifyLoginCode: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(
    VetForgetPasswordDto model,
  ) async {
    final url = Uri.parse("$baseUrl/forgot-password");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(model.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message":
              data["message"] ??
              "Reset password URL has been sent to the email successfully!",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to send reset password URL",
        };
      }
    } catch (e, stacktrace) {
      print('Error during forgotPassword: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/reset-password");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "token": token,
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Password reset successful",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to reset password",
        };
      }
    } catch (e, stacktrace) {
      print('Error during resetPassword: $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }
}
