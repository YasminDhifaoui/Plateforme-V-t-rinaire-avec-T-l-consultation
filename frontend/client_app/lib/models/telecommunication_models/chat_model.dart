import 'dart:convert';

class ChatMessage {
  final String senderName;
  final String text;
  final bool isSender;
  final DateTime sentAt;


  ChatMessage({
    required this.senderName,
    required this.text,
    required this.isSender,
    required this.sentAt,

  });

  static List<ChatMessage> chatMessagesFromJson(String str, String currentUserId) {
    final List<dynamic> jsonData = json.decode(str);

    return jsonData.map((msg) {
      final isSender = msg['senderId'] == currentUserId;

      return ChatMessage(
        senderName: msg['senderUsername'] ?? (isSender ? "You" : "Unknown"),
        text: msg['message'],
        isSender: isSender,
        sentAt: msg['sentAt'] != null && msg['sentAt'].toString().isNotEmpty
            ? DateTime.parse(msg['sentAt'])
            : DateTime.now(),

      );
    }).toList();
  }
}
