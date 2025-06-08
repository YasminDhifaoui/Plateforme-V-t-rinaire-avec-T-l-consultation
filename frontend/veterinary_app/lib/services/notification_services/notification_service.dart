import 'dart:convert';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../utils/base_url.dart';
import '../auth_services/token_service.dart';

class NotificationService {
  final String _baseUrl = BaseUrl.api;

  Future<Map<String, dynamic>> sendChatMessageNotification({
    required String recipientId,
    required String recipientAppType, // <<< NEW PARAMETER HERE

    required String senderId,
    required String senderName,
    required String messageContent,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    try {
      final String? token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        print('[NotificationService] No authentication token found. Cannot send notification trigger.');
        return {'success': false, 'message': 'Authentication token not found.'};
      }

      final Uri uri = Uri.parse('$_baseUrl/api/notifications/sendChatMessage');

      final Map<String, dynamic> requestBody = {
        'recipientId': recipientId,
        'recipientAppType': recipientAppType, // <<< ADDED TO REQUEST BODY

        'senderId': senderId,
        'senderName': senderName,
        'messageContent': messageContent,
        'notificationType': 'chat_message',
      };

      if (fileUrl != null && fileUrl.isNotEmpty) {
        requestBody['fileUrl'] = fileUrl;
        requestBody['fileName'] = fileName;
        requestBody['fileType'] = fileType;
      }

      print('[NotificationService] Sending chat notification trigger request to: $uri');
      print('[NotificationService] Request Body: ${json.encode(requestBody)}');
      print('[NotificationService] Request Headers: {Content-Type: application/json, Authorization: Bearer $token}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // --- ADDED DEBUG PRINTS FOR RESPONSE ---
      print('[NotificationService] Raw Response Status Code: ${response.statusCode}');
      print('[NotificationService] Raw Response Body: ${response.body}');
      print('[NotificationService] Raw Response Headers: ${response.headers}');
      // --- END ADDED DEBUG PRINTS ---

      // Only attempt JSON decode if the response body is not empty
      if (response.body.isEmpty) {
        print('[NotificationService] Response body is empty.');
        return {'success': false, 'message': 'Empty response from server. Status: ${response.statusCode}'};
      }

      final Map<String, dynamic> responseBody = json.decode(response.body); // This is where the error occurs

      if (response.statusCode == 200) {
        print('[NotificationService] Backend notification trigger response (200 OK): $responseBody');
        return {'success': true, 'message': responseBody['message'] ?? 'Notification trigger sent successfully.'};
      } else {
        print('[NotificationService] Backend notification trigger failed. Status: ${response.statusCode}, Body: $responseBody');
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to trigger notification on backend.'};
      }
    } catch (e) {
      print('[NotificationService] Exception during notification trigger: $e');
      return {'success': false, 'message': 'Network or unexpected error: ${e.toString()}'}; // Use e.toString() for full error
    }
  }
}