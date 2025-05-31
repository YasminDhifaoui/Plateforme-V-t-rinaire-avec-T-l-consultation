import 'package:signalr_core/signalr_core.dart';
import 'package:flutter/foundation.dart';

import '../../utils/base_url.dart';

// Update typedef to include file info
typedef MessageReceivedCallback = void Function(
    String senderUsername,
    String? message, // Now nullable
    String? fileUrl,
    String? fileName,
    String? fileType);

class SignalService {
  HubConnection? _connection;
  MessageReceivedCallback? onMessageReceived;

  Future<void> connect(String token) async {
    _connection = HubConnectionBuilder()
        .withUrl(
      '${BaseUrl.api}/chatHub',
      HttpConnectionOptions(
        accessTokenFactory: () async => token,
        logging: (level, message) => debugPrint(message),
      ),
    )
        .withAutomaticReconnect()
        .build();

    // Handle server-to-client messages
    _connection?.on("ReceiveMessage", (arguments) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(arguments?[0]);

      final senderUsername = data['SenderUsername'] as String;
      final message = data['Message'] as String?; // Can be null for file messages
      final fileUrl = data['FileUrl'] as String?; // New
      final fileName = data['FileName'] as String?; // New
      final fileType = data['FileType'] as String?; // New
      // final sentAt = data['SentAt']; // You can use this for display if needed

      if (onMessageReceived != null) {
        onMessageReceived!(senderUsername, message, fileUrl, fileName, fileType);
      }
    });

    await _connection?.start();
    debugPrint("Connected to SignalR hub");
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }

  // Modified sendMessage to accept file arguments
  Future<void> sendMessage(
      String receiverId,
      String? message, // Now nullable
          {String? fileUrl, String? fileName, String? fileType} // Optional named parameters for files
      ) async {
    if (_connection == null || _connection!.state != HubConnectionState.connected) {
      debugPrint("SignalR not connected.");
      return;
    }

    // Pass all arguments to the SignalR hub method
    await _connection!.invoke(
      'SendMessage',
      args: [receiverId, message, fileUrl, fileName, fileType],
    );
  }
}
