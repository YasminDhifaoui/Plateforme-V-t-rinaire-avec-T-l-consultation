import 'package:signalr_core/signalr_core.dart';
import 'package:flutter/foundation.dart';

typedef MessageReceivedCallback = void Function(String senderId, String message);

class SignalService {
  HubConnection? _connection;
  MessageReceivedCallback? onMessageReceived;

  Future<void> connect(String token) async {
    _connection = HubConnectionBuilder()
        .withUrl(
      'http://10.0.2.2:5000/chatHub',
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

      final senderId = data['SenderId'];
      final senderUsername = data['SenderUsername']; // ✅
      final message = data['Message'];
      final sentAt = data['SentAt'];

      if (onMessageReceived != null) {
        onMessageReceived!(senderUsername, message); // ✅ use username
      }
    });


    await _connection?.start();
    debugPrint("Connected to SignalR hub");
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }

  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    if (_connection == null || _connection!.state != HubConnectionState.connected) {
      debugPrint("SignalR not connected.");
      return;
    }

    await _connection!.invoke('SendMessage', args: [receiverId, message]);
  }
}
