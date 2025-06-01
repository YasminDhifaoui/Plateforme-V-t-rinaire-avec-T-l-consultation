import 'dart:convert';

class ChatMessage {
  final String senderName;
  final String? text; // Make text nullable
  final bool isSender;
  final DateTime sentAt;
  final String? fileUrl; // New: URL of the attached file
  final String? fileName; // New: Original name of the attached file
  final String? fileType; // New: Type of file (e.g., 'image', 'pdf', 'document')

  ChatMessage({
    required this.senderName,
    this.text, // Now nullable
    required this.isSender,
    required this.sentAt,
    this.fileUrl,
    this.fileName,
    this.fileType,
  });

  // Factory constructor to parse messages from JSON (e.g., chat history)
  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId = json['senderId']?.toString(); // Assuming 'senderId' is in your history JSON
    // You might need to adjust this if your history endpoint returns 'SenderUsername' directly
    final senderUsernameFromHistory = json['senderUsername']?.toString();

    return ChatMessage(
      senderName: senderUsernameFromHistory ?? 'Unknown', // Use username from history if available
      text: json['message'] as String?, // Cast to nullable string
      isSender: senderId == currentUserId,
      sentAt: DateTime.parse(json['sentDate'] as String),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
    );
  }

  static List<ChatMessage> chatMessagesFromJson(String str, String currentUserId) {
    final List<dynamic> jsonList = json.decode(str);
    return jsonList.map((x) => ChatMessage.fromJson(x, currentUserId)).toList();
  }
}
