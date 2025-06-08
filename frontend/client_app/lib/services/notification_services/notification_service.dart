// client_app/lib/services/notification_services/notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/base_url.dart';
import '../auth_services/token_service.dart';

class NotificationService {
  final String _baseUrl = BaseUrl.api;

  Future<Map<String, dynamic>> sendChatMessageNotification({
    required String recipientId,
    required String recipientAppType, // This is the crucial parameter
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
        'recipientAppType': recipientAppType, // This is the value being sent
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

      // --- CRITICAL DEBUG PRINTS ---
      print('[NotificationService DEBUG] Preparing to send chat notification:');
      print('  Target URL: $uri');
      print('  Recipient ID (from Flutter): $recipientId');
      print('  Recipient App Type (from Flutter): $recipientAppType'); // <<< THIS IS THE VALUE WE NEED TO CHECK
      print('  Sender ID (from Flutter): $senderId');
      print('  Full Request Body: ${json.encode(requestBody)}');
      // --- END CRITICAL DEBUG PRINTS ---

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('[NotificationService] Raw Response Status Code: ${response.statusCode}');
      print('[NotificationService] Raw Response Body: ${response.body}');
      print('[NotificationService] Raw Response Headers: ${response.headers}');

      if (response.body.isEmpty) {
        print('[NotificationService] Response body is empty.');
        return {'success': false, 'message': 'Empty response from server. Status: ${response.statusCode}'};
      }

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        print('[NotificationService] Backend notification trigger response (200 OK): $responseBody');
        return {'success': true, 'message': responseBody['message'] ?? 'Notification trigger sent successfully.'};
      } else {
        print('[NotificationService] Backend notification trigger failed. Status: ${response.statusCode}, Body: $responseBody');
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to trigger notification on backend.'};
      }
    } catch (e) {
      print('[NotificationService] Exception during notification trigger: $e');
      return {'success': false, 'message': 'Network or unexpected error: ${e.toString()}'};
    }
  }
}