import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/chat_model.dart';
import '../../services/telecommunication_services/chat_signal_service.dart';

class ChatPage extends StatefulWidget {
  final String token;
  final String receiverId;

  const ChatPage({Key? key, required this.token, required this.receiverId})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];

  final SignalService _signalService = SignalService();

  String? _currentUserId; // ✅ Store current user id here

  @override
  void initState() {
    super.initState();

    _currentUserId = getUserIdFromToken(widget.token); // ✅ Store once

    // Connect to the SignalR hub
    _signalService.connect(widget.token);

    // Handle incoming messages from SignalR
    _signalService.onMessageReceived = (from, message) {
      if (from == _currentUserId) {
        // ✅ Skip messages sent by yourself
        return;
      }

      print("Message from $from: $message");

      print('FROM: $from');
      print('MY ID: $_currentUserId');
      print('MATCH: ${from == _currentUserId}');

      setState(() {
        _messages.add(ChatMessage(
          senderName: from,
          text: message,
          isSender: false,
        ));
      });
    };

    _fetchMessages();
  }
  String getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';

      final payloadBase64 = base64.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      final decoded = json.decode(payloadString);

      print("Decoded JWT payload: $decoded");

      final userId = decoded['Id'];
      print("Extracted user ID: $userId");

      return userId?.toString() ?? '';
    } catch (e) {
      print("Error decoding token: $e");
      return '';
    }
  }


  Future<void> _fetchMessages() async {
    final receiverId = widget.receiverId;

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:5000/messages/conversation?user1=$_currentUserId&user2=$receiverId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _messages = ChatMessage.chatMessagesFromJson(
          response.body,
          _currentUserId ?? '',
        );
      });
    } else {
      print('Failed to fetch messages');
    }
  }

  void _sendMessage(String message) {
    final receiverId = widget.receiverId;

    _signalService.sendMessage("", receiverId, message);

    setState(() {
      _messages.add(ChatMessage(
        senderName: "You",
        text: message,
        isSender: true,
      ));
    });

    _controller.clear();
  }

  @override
  void dispose() {
    _signalService.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.senderName),
                  subtitle: Text(message.text),
                  tileColor:
                  message.isSender ? Colors.blue[100] : Colors.grey[100],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Enter message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
