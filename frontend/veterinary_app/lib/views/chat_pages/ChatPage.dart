import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/chat_models/chat_model.dart';
import '../../services/chat_services/chat_signal_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/base_url.dart';
import '../video_call_pages/video_call_screen.dart';

// For file picking - changed to file_selector
import 'package:file_selector/file_selector.dart';
// For opening URLs (e.g., PDFs in browser)
import 'package:url_launcher/url_launcher.dart';

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

    // Update onMessageReceived to handle new file parameters
    _signalService.onMessageReceived = (from, message, fileUrl, fileName, fileType) {
      // This check prevents duplicating messages sent by self and received via SignalR
      // It compares the 'from' (senderUsername) with the current user's username
      if (from.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            senderName: _getDisplayName(from),
            text: message,
            isSender: false,
            sentAt: DateTime.now(),
            fileUrl: fileUrl,
            fileName: fileName,
            fileType: fileType,
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

  String _getDisplayName(String senderUsername) {
    // Assuming senderUsername from SignalR is the username
    if (senderUsername.trim().toLowerCase() == widget.receiverUsername.trim().toLowerCase()) {
      return widget.receiverUsername; // Display receiver's actual username
    } else if (senderUsername.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
      return "You"; // Display "You" for current user's messages
    } else {
      return senderUsername; // Fallback
    }
  }

  // Method to send a text message
  void _sendMessage(String message) {
    if (_currentUserId == null) {
      _showSnackBar('User not authenticated. Cannot send message.', isSuccess: false);
      return;
    }
    if (message.trim().isEmpty) return; // Don't send empty messages

    _signalService.sendMessage(widget.receiverId, message);

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

  // New method to pick and send a file using file_selector
  Future<void> _pickAndSendFile() async {
    if (_currentUserId == null) {
      _showSnackBar('User not authenticated. Cannot send file.', isSuccess: false);
      return;
    }

    // Define allowed file types for file_selector
    const XTypeGroup fileTypeGroup = XTypeGroup(
      label: 'Files',
      extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt'],
    );

    // Use openFile from file_selector
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[fileTypeGroup]);

    if (file != null) {
      String filePath = file.path;
      String fileName = file.name;
      String fileExtension = file.name.split('.').last.toLowerCase(); // Extract extension from name

      _showSnackBar('Uploading file...', isSuccess: true); // Inform user about upload

      // 1. Upload the file to your backend API
      final uploadedFileUrl = await _uploadFileToServer(filePath, fileName);

      if (uploadedFileUrl != null) {
        // Determine file type for display purposes
        String fileType;
        if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
          fileType = 'image';
        } else if (['pdf'].contains(fileExtension)) {
          fileType = 'pdf';
        } else if (['doc', 'docx', 'txt'].contains(fileExtension)) {
          fileType = 'document';
        } else {
          fileType = 'other'; // Generic fallback for other file types
        }

        // 2. Send the message via SignalR with file details
        _signalService.sendMessage(
          widget.receiverId,
          null, // No text message for file attachments
          fileUrl: uploadedFileUrl,
          fileName: fileName,
          fileType: fileType,
        );

        setState(() {
          _messages.add(
            ChatMessage(
              senderName: "You", // Display "You" for self-sent messages
              text: null, // No text content for file messages
              isSender: true,
              sentAt: DateTime.now(),
              fileUrl: uploadedFileUrl,
              fileName: fileName,
              fileType: fileType,
            ),
          );
        });
        _scrollToBottom();
      } else {
        _showSnackBar('File upload failed.', isSuccess: false);
      }
    }
  }

  // Method to upload file to your C# backend API
  Future<String?> _uploadFileToServer(String filePath, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseUrl.api}/api/Files/upload'), // Your file upload API endpoint
      );
      // Use http.MultipartFile.fromPath for file_selector as well
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      request.headers['Authorization'] = 'Bearer ${widget.token}'; // Authenticate the upload request

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['fileUrl'] as String?; // Assuming your API returns the URL in 'fileUrl'
      } else {
        print('File upload failed with status: ${response.statusCode}. Response: ${await response.stream.bytesToString()}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
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
        backgroundColor: isSuccess ? kAccentGreen : Colors.red.shade600,
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
    final bubbleColor = message.isSender ? kAccentGreen : Colors.grey.shade200;
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
              crossAxisAlignment: message.isSender
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600, color: senderNameColor),
                ),
                const SizedBox(height: 4),
                // Conditional rendering based on message type (text or file)
                if (message.text != null && message.text!.isNotEmpty)
                  Text(
                    message.text!,
                    style: textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                if (message.fileUrl != null && message.fileUrl!.isNotEmpty)
                  _buildFileContent(message, textColor, textTheme), // Helper function for file content
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

  // Helper widget to display file content within the message bubble
  Widget _buildFileContent(ChatMessage message, Color textColor, TextTheme textTheme) {
    if (message.fileType == 'image' && message.fileUrl != null) {
      // For images, display the image directly
      return GestureDetector(
        onTap: () {
          // Implement image viewer (e.g., show in dialog or new screen)
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    '${BaseUrl.api}${message.fileUrl!}', // Prepend base URL
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 50),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            '${BaseUrl.api}${message.fileUrl!}', // Prepend base URL
            width: 200, // Max width for image in chat bubble
            height: 200, // Max height
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: textColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.red, size: 40),
                      Text('Image failed to load', style: textTheme.bodySmall?.copyWith(color: Colors.red)),
                    ],
                  ),
                ),
          ),
        ),
      );
    } else if (message.fileUrl != null) {
      // For documents (PDF, DOC, TXT, etc.), show an icon and filename
      IconData fileIcon;
      switch (message.fileType) {
        case 'pdf':
          fileIcon = Icons.picture_as_pdf_rounded;
          break;
        case 'document':
          fileIcon = Icons.insert_drive_file_rounded;
          break;
        default:
          fileIcon = Icons.attach_file_rounded;
      }

      return InkWell(
        onTap: () async {
          final url = '${BaseUrl.api}${message.fileUrl!}';
          print('--- Attempting to open URL: $url ---'); // ADDED THIS LINE FOR EXTRA CLARITY
          if (await canLaunchUrl(Uri.parse(url))) {
            try {
              await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
              print('Successfully launched URL: $url');
            } catch (e) {
              print('Error launching URL ($url): $e');
              _showSnackBar('Could not open file: $e', isSuccess: false);
            }
          } else {
            print('Cannot launch URL: $url');
            _showSnackBar('Could not open file. No app found to handle this type or URL is invalid. URL: $url', isSuccess: false);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fileIcon, color: textColor, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName ?? 'File',
                style: textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  decoration: TextDecoration.underline, // Indicate it's clickable
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // Should not happen if logic is correct
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
                    borderSide: BorderSide(color: kAccentGreen, width: 1.5),
                  ),
                  // Add an attachment icon here
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: kAccentGreen),
                    onPressed: _pickAndSendFile, // Call the new file picking method
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: kAccentGreen, // Themed send button
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
        backgroundColor: kAccentGreen, // Themed AppBar background
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
              child: Icon(Icons.person_rounded, color: kAccentGreen, size: 20), // Themed person icon
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
