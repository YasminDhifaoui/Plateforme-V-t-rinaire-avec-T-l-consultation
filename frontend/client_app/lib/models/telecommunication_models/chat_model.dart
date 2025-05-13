import 'dart:convert';

class ChatMessage {
  final String senderName;
  final String text;
  final bool isSender;

  ChatMessage({
    required this.senderName,
    required this.text,
    required this.isSender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderName: json['senderName'],
      text: json['text'],
      isSender: json['isSender'],
    );
  }

  static List<ChatMessage> chatMessagesFromJson(String jsonStr) {
    final jsonData = json.decode(jsonStr) as List;
    return jsonData.map((message) => ChatMessage.fromJson(message)).toList();
  }
}
