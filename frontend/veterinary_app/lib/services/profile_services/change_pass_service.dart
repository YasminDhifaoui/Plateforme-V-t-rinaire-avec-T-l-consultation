// ... (your existing imports and ApiService class definition)
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:veterinary_app/utils/base_url.dart';

import '../../models/profile_models/VetChangePasswordModel.dart'; // <--- Check this path and class name

// Make sure to import your new DTO

class changePassService {
  static final String baseUrl = "${BaseUrl.api}/api/veterinaire/profile"; // Adjust if your vet base URL is different

  // ... (your existing methods like registerClient, loginClient, forgotPassword, etc.)

  /// Change password for a logged-in Vet user
  Future<Map<String, dynamic>> changeVetPassword(
      VetChangePasswordDto changePasswordDto, String jwtToken) async {
    final url = Uri.parse("$baseUrl/change-password");

    try {
      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken", // IMPORTANT: Send the JWT token
        },
        body: jsonEncode(changePasswordDto.toJson()),
      )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response from server"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"] ?? "Password changed successfully."};
      } else {
        return {"success": false, "message": data["message"] ?? "Failed to change password."};
      }
    } catch (e, stacktrace) {
      print('Error during changeVetPassword (Vet): $e');
      print('Stacktrace: $stacktrace');
      return {"success": false, "message": "Error: $e"};
    }
  }

}