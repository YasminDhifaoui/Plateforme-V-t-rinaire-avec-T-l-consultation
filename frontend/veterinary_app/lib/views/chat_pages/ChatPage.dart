import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart'; // Import TokenService for vet app
import 'package:veterinary_app/services/chat_services/chat_signal_service.dart';
import 'package:veterinary_app/utils/app_colors.dart'; // Assuming kAccentGreen is defined here
import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/views/video_call_pages/video_call_screen.dart';

// For file picking - changed to file_selector
import 'package:file_selector/file_selector.dart';
// For opening URLs (e.g., PDFs in browser)
import 'package:url_launcher/url_launcher.dart';
// For camera and gallery access
import 'package:image_picker/image_picker.dart';
// For saving images
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart'; // For temporary file path
import 'package:permission_handler/permission_handler.dart'; // For permission handling

import '../../models/chat_models/chat_model.dart';
import '../../services/notification_services/notification_service.dart';

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
  final NotificationService _notificationService = NotificationService(); // Correctly instantiated
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];

  String? _currentUserId;
  String? _currentUsername;

  // This state variable controls the visibility of the "Scroll to Bottom" button
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _initializeChatPage(); // Use the new initialization method
    _signalService.connect(widget.token);

    _signalService.onMessageReceived = (from, message, fileUrl, fileName, fileType) {
      if (from.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            senderName: _getDisplayName(from),
            text: message,
            isSender: false,
            sentAt: DateTime.now(), // Use DateTime.now() for received messages
            fileUrl: fileUrl,
            fileName: fileName,
            fileType: fileType,
          ),
        );
        // Sort messages by sentAt timestamp to maintain chronological order
        _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      });

      _scrollToBottom(); // Scrolls to bottom when a new message is received
    };

    _scrollController.addListener(_scrollListener);
  }

  // Async initialization method to get current user details from TokenService
  Future<void> _initializeChatPage() async {
    _currentUserId = await TokenService.getUserId();
    _currentUsername = await TokenService.getUsername();
    print('[ChatPage] Current User ID: $_currentUserId, Username: $_currentUsername');

    if (_currentUserId == null || _currentUsername == null) {
      _showSnackBar('Your session details are missing. Please log in again.', isSuccess: false);
      // Optionally, navigate back to login page if essential data is missing
    }

    _fetchMessages(); // Fetch messages after current user details are loaded
  }

  Future<void> _fetchMessages() async {
    // Ensure _currentUserId is set before fetching messages
    if (_currentUserId == null) {
      _showSnackBar('Cannot fetch messages: Current user ID is unknown.', isSuccess: false);
      return;
    }

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
          // Sort messages by sentAt timestamp after fetching history
          _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        });
        // Scrolls to bottom after fetching and setting initial messages
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
    if (senderUsername.trim().toLowerCase() == widget.receiverUsername.trim().toLowerCase()) {
      return widget.receiverUsername;
    } else if (senderUsername.trim().toLowerCase() == _currentUsername?.trim().toLowerCase()) {
      return "You";
    } else {
      return senderUsername;
    }
  }

  void _sendMessage(String message) async {
    if (_currentUserId == null || _currentUsername == null) {
      _showSnackBar('User authentication details not available. Please re-login.', isSuccess: false);
      return;
    }
    if (message.trim().isEmpty) return;

    _signalService.sendMessage(widget.receiverId, message);

    setState(() {
      _messages.add(
        ChatMessage(
          senderName: "You",
          text: message,
          isSender: true,
          sentAt: DateTime.now(),
        ),
      );
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    });

    _controller.clear();
    _scrollToBottom();

    // Trigger FCM notification via backend for the recipient
    final notificationResult = await _notificationService.sendChatMessageNotification(
      recipientId: widget.receiverId,
      senderId: _currentUserId!,
      senderName: _currentUsername!, // This will be the vet's username
      messageContent: message,
      // No file details for a text message
    );

    if (!notificationResult['success']) {
      print('[ChatPage] Failed to send chat notification: ${notificationResult['message']}');
      // Optionally, show a subtle error to the user if the notification part failed
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_currentUserId == null || _currentUsername == null) {
      _showSnackBar('User authentication details not available. Please re-login.', isSuccess: false);
      return;
    }

    const XTypeGroup fileTypeGroup = XTypeGroup(
      label: 'Files',
      extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[fileTypeGroup]);

    if (file != null) {
      String filePath = file.path;
      String fileName = file.name;
      String fileExtension = file.name.split('.').last.toLowerCase();

      _showSnackBar('Uploading file...', isSuccess: true);

      final uploadedFileUrl = await _uploadFileToServer(filePath, fileName);

      if (uploadedFileUrl != null) {
        String fileType;
        if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
          fileType = 'image';
        } else if (['pdf'].contains(fileExtension)) {
          fileType = 'pdf';
        } else if (['doc', 'docx', 'txt'].contains(fileExtension)) {
          fileType = 'document';
        } else {
          fileType = 'other';
        }

        _signalService.sendMessage(
          widget.receiverId,
          null,
          fileUrl: uploadedFileUrl,
          fileName: fileName,
          fileType: fileType,
        );

        setState(() {
          _messages.add(
            ChatMessage(
              senderName: "You",
              text: null,
              isSender: true,
              sentAt: DateTime.now(),
              fileUrl: uploadedFileUrl,
              fileName: fileName,
              fileType: fileType,
            ),
          );
          _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        });
        _scrollToBottom();

        // Trigger FCM notification via backend for file message
        final notificationResult = await _notificationService.sendChatMessageNotification(
          recipientId: widget.receiverId,
          senderId: _currentUserId!,
          senderName: _currentUsername!, // This will be the vet's username
          messageContent: 'Sent a file: ${fileName}', // A descriptive message for notification
          fileUrl: uploadedFileUrl,
          fileName: fileName,
          fileType: fileType,
        );

        if (!notificationResult['success']) {
          print('[ChatPage] Failed to send file notification: ${notificationResult['message']}');
        }
      } else {
        _showSnackBar('File upload failed.', isSuccess: false);
      }
    }
  }

  Future<void> _takeAndSendPicture() async {
    if (_currentUserId == null || _currentUsername == null) {
      _showSnackBar('User authentication details not available. Please re-login.', isSuccess: false);
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      String filePath = photo.path;
      String fileName = photo.name;

      _showSnackBar('Uploading picture...', isSuccess: true);

      final uploadedFileUrl = await _uploadFileToServer(filePath, fileName);

      if (uploadedFileUrl != null) {
        String fileType = 'image';

        _signalService.sendMessage(
          widget.receiverId,
          null,
          fileUrl: uploadedFileUrl,
          fileName: fileName,
          fileType: fileType,
        );

        setState(() {
          _messages.add(
            ChatMessage(
              senderName: "You",
              text: null,
              isSender: true,
              sentAt: DateTime.now(),
              fileUrl: uploadedFileUrl,
              fileName: fileName,
              fileType: fileType,
            ),
          );
          _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        });
        _scrollToBottom();

        // Trigger FCM notification via backend for picture message
        final notificationResult = await _notificationService.sendChatMessageNotification(
          recipientId: widget.receiverId,
          senderId: _currentUserId!,
          senderName: _currentUsername!, // This will be the vet's username
          messageContent: 'Sent a picture: ${fileName}', // A descriptive message for notification
          fileUrl: uploadedFileUrl,
          fileName: fileName,
          fileType: fileType,
        );

        if (!notificationResult['success']) {
          print('[ChatPage] Failed to send picture notification: ${notificationResult['message']}');
        }
      } else {
        _showSnackBar('Picture upload failed.', isSuccess: false);
      }
    }
  }

  Future<String?> _uploadFileToServer(String filePath, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseUrl.api}/api/Files/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['fileUrl'] as String?;
      } else {
        print('File upload failed with status: ${response.statusCode}. Response: ${await response.stream.bytesToString()}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _downloadAndSaveImage(String imageUrl, String fileName) async {
    _showSnackBar('Downloading image...', isSuccess: true);
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      } else if (Platform.isIOS) {
        status = await Permission.photosAddOnly.request();
      } else {
        status = PermissionStatus.granted;
      }

      if (status.isGranted) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final directory = await getTemporaryDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          final result = await ImageGallerySaverPlus.saveFile(file.path, name: fileName);
          if (result['isSuccess']) {
            _showSnackBar('Image saved to gallery!', isSuccess: true);
          } else {
            _showSnackBar('Failed to save image to gallery: ${result['errorMessage'] ?? 'Unknown error'}', isSuccess: false);
          }
        } else {
          _showSnackBar('Failed to download image: Server responded with ${response.statusCode}', isSuccess: false);
        }
      } else {
        _showSnackBar('Permission denied to save image.', isSuccess: false);
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      _showSnackBar('Error downloading image: $e', isSuccess: false);
      print('Error downloading image: $e');
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

  // The _scrollToTop method is no longer used by the FAB, but kept for reference
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Explicitly animate to 0.0 for the top
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Named listener for _scrollController to manage button visibility
  void _scrollListener() {
    final double currentScroll = _scrollController.position.pixels;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    const double threshold = 50.0; // Pixels from the bottom to show the button

    // Show button if not at the very bottom
    if (currentScroll < maxScroll - threshold && !_showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = true;
      });
    }
    // Hide button if at or near the very bottom
    else if (currentScroll >= maxScroll - threshold && _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kAccentGreen : Colors.red.shade600, // Consistent color usage
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _signalService.onMessageReceived = null;
    _signalService.disconnect();
    _controller.dispose();
    _scrollController.removeListener(_scrollListener); // Remove the named listener
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
                if (message.text != null && message.text!.isNotEmpty)
                  Text(
                    message.text!,
                    style: textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                if (message.fileUrl != null && message.fileUrl!.isNotEmpty)
                  _buildFileContent(message, textColor, textTheme),
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

  Widget _buildFileContent(ChatMessage message, Color textColor, TextTheme textTheme) {
    if (message.fileType == 'image' && message.fileUrl != null) {
      final fullImageUrl = '${BaseUrl.api}${message.fileUrl!}';
      final imageFileName = message.fileName ?? 'image.jpg';

      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.black54,
              elevation: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    fullImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 50),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: FloatingActionButton(
                      backgroundColor: kAccentGreen,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _downloadAndSaveImage(fullImageUrl, imageFileName);
                      },
                      child: const Icon(Icons.download_rounded, color: Colors.white),
                      tooltip: 'Download Image',
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
            fullImageUrl,
            width: 200,
            height: 200,
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
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.red, size: 40),
                      Text('Image failed to load', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
          ),
        ),
      );
    } else if (message.fileUrl != null) {
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
          print('--- Attempting to open URL: $url ---');
          try {
            if (!await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            )) {
              print('Cannot launch URL: $url');
              _showSnackBar(
                'Could not open file. No app found to handle this type or URL is invalid. URL: $url',
                isSuccess: false,
              );
            } else {
              print('Successfully launched URL: $url');
            }
          } catch (e) {
            print('Error launching URL ($url): $e');
            _showSnackBar(
              'Error opening file: ${e.toString()}',
              isSuccess: false,
            );
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
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessageInput(TextTheme textTheme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
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
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file_rounded, color: kAccentGreen),
                        onPressed: _pickAndSendFile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: kAccentGreen),
                        onPressed: _takeAndSendPicture,
                      ),
                    ],
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
              backgroundColor: kAccentGreen,
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: kAccentGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.person_rounded, color: kAccentGreen, size: 20),
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
                  color: kAccentGreen,
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
                  Icons.video_call_rounded,
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0).copyWith(bottom: 160.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], textTheme),
            ),
          ),
          _buildMessageInput(textTheme),
        ],
      ),
      floatingActionButton: _showScrollToBottomButton
          ? FloatingActionButton(
        onPressed: _scrollToBottom,
        backgroundColor: kAccentGreen,
        mini: true,
        child: const Icon(Icons.arrow_downward, color: Colors.white),
        tooltip: 'Scroll to Latest Messages',
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
    );
  }
}