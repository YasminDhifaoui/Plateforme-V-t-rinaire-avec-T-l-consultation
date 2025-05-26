import 'package:flutter/material.dart';
import '../../models/conv_models/conv_model.dart';
import '../../services/conv_services/conv_service.dart';
import '../chat_pages/ChatPage.dart';

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

class ConversationsPage extends StatelessWidget {
  final String token;
  final ConvService _convService = ConvService();

  ConversationsPage({Key? key, required this.token}) : super(key: key);

  // Helper to show themed SnackBar feedback
  void _showSnackBar(BuildContext context, String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        title: Text(
          'Inbox',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
        // No leading icon needed if this is a top-level page or handled by parent navigation
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _convService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kPrimaryBlue)); // Themed loading indicator
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded, // Error icon
                      color: Colors.red.shade400,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load conversations: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // In a StatelessWidget, you can't directly trigger FutureBuilder refresh.
                        // A common pattern is to wrap this in a StatefulWidget or use a state management solution (Provider, Riverpod, BLoC).
                        // For now, inform the user or suggest navigating back and forth.
                        _showSnackBar(context, "Cannot refresh directly. Please navigate back and forth.", isSuccess: false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Retry', style: textTheme.labelLarge),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded, // Chat icon for no conversations
                    color: Colors.grey.shade400,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations found.',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start a chat with a veterinarian to see it here!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            );
          } else {
            final conversations = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return Card(
                  elevation: 6, // More pronounced shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // More rounded corners
                  ),
                  color: Colors.white, // White card background
                  child: InkWell( // Added InkWell for ripple effect
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            token: token,
                            receiverId: conv.userId,
                            receiverUsername: conv.username,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryBlue, // Themed avatar background
                              border: Border.all(color: kAccentBlue, width: 2), // Accent border
                            ),
                            child: Center(
                              child: Text(
                                conv.username.isNotEmpty
                                    ? conv.username[0].toUpperCase()
                                    : '?',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv.username,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryBlue, // Themed title
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conv.email,
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54), // Subtle subtitle
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 20, color: kAccentBlue), // Themed trailing icon
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}