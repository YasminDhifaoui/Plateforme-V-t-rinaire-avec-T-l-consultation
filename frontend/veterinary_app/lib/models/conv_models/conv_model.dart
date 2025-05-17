// models/conversation.dart
class Conversation {
  final String userId;
  final String username;
  final String email;

  Conversation({
    required this.userId,
    required this.username,
    required this.email,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
    );
  }
}
