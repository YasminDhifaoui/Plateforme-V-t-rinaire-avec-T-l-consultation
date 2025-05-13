import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/telecommunication_models/chat_model.dart';
import '../../services/telecommunication_services/signal_service.dart';

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

  @override
  void initState() {
    super.initState();

    // Connect to the SignalR hub
    _signalService.connect(widget.token);

    // Handle incoming messages from SignalR
    _signalService.onMessageReceived = (from, message) {
      print("Message from $from: $message");
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

  Future<void> _fetchMessages() async {
    final token = widget.token;
    final receiverId = widget.receiverId;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/messages?receiverId=$receiverId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _messages = ChatMessage.chatMessagesFromJson(response.body);
      });
    } else {
      print('Failed to fetch messages');
    }
  }

  void _sendMessage(String message) {
    final receiverId = widget.receiverId;

    _signalService.sendMessage(receiverId, message);

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
                  tileColor: message.isSender ? Colors.blue[100] : Colors.grey[100],
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
