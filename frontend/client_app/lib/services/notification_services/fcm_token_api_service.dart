// veterinary_app/lib/services/fcm_token_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client_app/utils/base_url.dart'; // Ensure BaseUrl is defined here

class FcmTokenApiService {
  static final String _baseUrl = BaseUrl.api;
  static Future<void> saveUserFcmToken(String userId, String fcmToken, String appType) async {
    final Uri uri = Uri.parse('$_baseUrl/api/users/savefcmtoken'); // Your backend endpoint for saving tokens
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // If your backend endpoint requires authentication,
          // you'd add the vet's JWT token here.
          // 'Authorization': 'Bearer ${await TokenService.getToken()}',
        },
        body: json.encode({
          'userId': userId,
          'fcmToken': fcmToken,
          'appType': appType, // Pass 'vet' or 'client' to differentiate
        }),
      );

      if (response.statusCode == 200) {
        print('[FcmTokenApiService] FCM token saved/updated successfully for user $userId ($appType).');
      } else {
        print('[FcmTokenApiService] Failed to save FCM token for user $userId ($appType). Status: ${response.statusCode}, Body: ${response.body}');
        // Optionally throw an exception if you want to handle failures more aggressively
        // throw Exception('Failed to save FCM token: ${response.body}');
      }
    } catch (e) {
      print('[FcmTokenApiService] Error saving FCM token: $e');
      // throw Exception('Error saving FCM token: $e'); // Re-throw if you want errors propagated
    }
  }
}