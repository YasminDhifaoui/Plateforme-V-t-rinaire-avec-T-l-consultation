import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:veterinary_app/utils/base_url.dart';
import '../../models/chat_models/chat_model.dart';
import '../../services/notification_handle/message_notifier.dart'; // Keep if used for unread count
import '../../services/chat_services/chat_signal_service.dart';
import '../video_call_pages/video_call_screen.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

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
      if (from.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
        // This check prevents duplicating messages sent by self and received via SignalR
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            senderName: _getDisplayName(from),
            text: message,
            isSender: false,
            sentAt: DateTime.now(),
          ),
        );
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
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseUrl.api}/api/chat/history/$_currentUserId/${widget.receiverId}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages = ChatMessage.chatMessagesFromJson(
            response.body,
            _currentUserId ?? '',
          );
        });
        _scrollToBottom();
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        _showSnackBar('Failed to load chat history.', isSuccess: false);
      }
    } catch (e) {
      print('Error fetching messages: $e');
      _showSnackBar('Network error. Could not load chat history.', isSuccess: false);
    }
  }

  String _getDisplayName(String senderId) {
    // Assuming senderId from SignalR is the username
    if (senderId.trim().toLowerCase() == widget.receiverUsername.trim().toLowerCase()) {
      return widget.receiverUsername; // Display receiver's actual username
    } else if (senderId.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
      return "You"; // Display "You" for current user's messages
    } else {
      return senderId; // Fallback
    }
  }

  void _sendMessage(String message) {
    if (_currentUserId == null) {
      _showSnackBar('User not authenticated. Cannot send message.', isSuccess: false);
      return;
    }

    _signalService.sendMessage(_currentUserId!, widget.receiverId, message);

    setState(() {
      _messages.add(
        ChatMessage(
          senderName: "You", // Display "You" for self-sent messages
          text: message,
          isSender: true,
          sentAt: DateTime.now(),
        ),
      );
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper to show themed SnackBar feedback
  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _signalService.onMessageReceived = null; // Clear callback
    _signalService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message, TextTheme textTheme) {
    final alignment =
    message.isSender ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isSender ? kPrimaryGreen : Colors.grey.shade200;
    final textColor = message.isSender ? Colors.white : Colors.black87;
    final senderNameColor = message.isSender ? Colors.white70 : Colors.black54;

    final radius = message.isSender
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    final formattedTime = DateFormat('hh:mm a').format(message.sentAt);

    return Column(
      crossAxisAlignment:
      message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
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
                  style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600, color: senderNameColor),
                ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  style: textTheme.bodyMedium?.copyWith(color: textColor),
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
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput(TextTheme textTheme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: kPrimaryGreen, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: kPrimaryGreen, // Themed send button
              radius: 24, // Slightly larger
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white), // Modern send icon
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    _sendMessage(_controller.text.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: AppBar(
        backgroundColor: kPrimaryGreen, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18, // Smaller avatar in app bar
              child: Icon(Icons.person_rounded, color: kPrimaryGreen, size: 20), // Themed person icon
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.receiverUsername,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                print('Video call button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallScreen(
                      targetUserId: widget.receiverId,
                      isCaller: true,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: kAccentGreen, // Use kAccentGreen for video call button
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.video_call_rounded, // Modern video call icon
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], textTheme),
            ),
          ),
          _buildMessageInput(textTheme),
        ],
      ),
    );
  }
}