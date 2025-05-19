import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/chat_models/chat_model.dart';
import '../../services/notification_handle/message_notifier.dart';
import '../../services/chat_services/chat_signal_service.dart';
import '../video_call_pages/video_call_screen.dart';

class ChatPage extends StatefulWidget {
  final String token;
  final String receiverId;
  final String receiverUsername;

  const ChatPage({
    Key? key,
    required this.token,
    required this.receiverId,
    required this.receiverUsername,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SignalService _signalService = SignalService();

  List<ChatMessage> _messages = [];

  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _extractTokenDetails(widget.token);
    _signalService.connect(widget.token);

    _signalService.onMessageReceived = (from, message) {
      if (from.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) return;

      setState(() {
        _messages.add(ChatMessage(
          senderName: _getDisplayName(from),
          text: message,
          isSender: false,
          sentAt: DateTime.now(),
        ));
      });

      _scrollToBottom();
};

    _fetchMessages();
  }

  void _extractTokenDetails(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      final payloadBase64 = base64.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      final decoded = json.decode(payloadString);

      _currentUserId = decoded['Id']?.toString();
      _currentUsername = decoded['sub']?.toString();
    } catch (e) {
      print("Error decoding token: $e");
    }
  }

  Future<void> _fetchMessages() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/chat/history/$_currentUserId/${widget.receiverId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _messages = ChatMessage.chatMessagesFromJson(response.body, _currentUserId ?? '');
      });

      _scrollToBottom();
    } else {
      print('Failed to fetch messages');
    }
  }

  String _getDisplayName(String senderId) {
    return (senderId.trim().toLowerCase() == _currentUserId?.trim().toLowerCase())
        ? "${_currentUsername ?? "Me"} (me)"
        : senderId;
  }

  void _sendMessage(String message) {
    if (_currentUserId == null) return;

    _signalService.sendMessage(_currentUserId!, widget.receiverId, message);

    setState(() {
      _messages.add(ChatMessage(
        senderName: "${_currentUsername ?? "Me"} (me)",
        text: message,
        isSender: true,
        sentAt: DateTime.now(),
      ));
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _signalService.onMessageReceived = null;
    _signalService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final alignment = message.isSender ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isSender ? Colors.green[400] : Colors.green[100];
    final radius = message.isSender
        ? BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    )
        : BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    final formattedTime = DateFormat('hh:mm a').format(message.sentAt);

    return Column(
      crossAxisAlignment: message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: alignment,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
              message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                SizedBox(height: 4),
                Text(
                  message.text,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: message.isSender ? 0 : 20,
            right: message.isSender ? 20 : 0,
            bottom: 4,
          ),
          child: Text(
            formattedTime,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.green[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    _sendMessage(_controller.text.trim());
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green),
            ),
            SizedBox(width: 10),
            Text(
              widget.receiverUsername,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                targetUserId: "123", // Replace with dynamic user ID
                ),
                ),
                );
                print('Video call button pressed');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent.shade700, // greenish color for video call
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.video_call,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
