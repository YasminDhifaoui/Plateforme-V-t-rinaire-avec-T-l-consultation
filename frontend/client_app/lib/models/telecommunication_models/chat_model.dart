import 'dart:convert';

class ChatMessage {
  final String senderName;
  final String text;
  final bool isSender;

  ChatMessage({required this.senderName, required this.text, required this.isSender});
  static List<ChatMessage> chatMessagesFromJson(String jsonData, String currentUserId) {
    final data = json.decode(jsonData) as List;

    return data.map((msg) {
      return ChatMessage(
        senderName: msg['SenderUsername'] ?? 'Unknown',
        text: msg['Message'] ?? '',
        isSender: (msg['SenderId']?.toString() ?? '') == currentUserId,
      );
    }).toList();
  }

}
