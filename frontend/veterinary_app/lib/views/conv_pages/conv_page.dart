import 'package:flutter/material.dart';
import '../../models/conv_models/conv_model.dart';
import '../../services/conv_services/conv_service.dart';
import '../chat_pages/ChatPage.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class ConversationsPage extends StatelessWidget {
  final String token;
  final ConvService _convService = ConvService();

  ConversationsPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          'Inbox ',
          style: textTheme.titleLarge?.copyWith(color: Colors.white), // Themed title style
        ),
        // No leading icon usually needed if this is a bottom nav destination or first screen
        centerTitle: true,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _convService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kPrimaryGreen), // Themed loading indicator
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load conversations: ${snapshot.error}',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // In a StatelessWidget, you can't setState to re-run FutureBuilder directly.
                        // You might need to wrap this in a StatefulWidget or use a GlobalKey if you want to refresh.
                        // For simplicity, navigating back and then re-entering the page might be an option.
                        // Or, consider moving FutureBuilder to a StatefulWidget's body.
                        // For now, this button is purely illustrative if no stateful refresh mechanism exists here.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Couldn't refresh. Please try navigating back and forth."),
                            backgroundColor: kAccentGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: Text('Retry', style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                      ),
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
                    Icons.chat_bubble_outline_rounded, // Engaging icon for no conversations
                    color: kAccentGreen,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No conversations found yet!',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new chat to see it here.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                    textAlign: TextAlign.center,
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
                  // Card styling now consistent with theme via CardThemeData in main.dart
                  // You can override if needed:
                  elevation: 6, // Slightly more prominent elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Slightly more rounded
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, // Increased padding
                      vertical: 14, // Increased padding
                    ),
                    leading: CircleAvatar(
                      radius: 28, // Slightly larger avatar
                      backgroundColor: kPrimaryGreen, // Themed background for avatar
                      child: Text(
                        conv.username.isNotEmpty
                            ? conv.username[0].toUpperCase()
                            : '?',
                        style: textTheme.titleLarge?.copyWith(color: Colors.white), // Themed text style
                      ),
                    ),
                    title: Text(
                      conv.username,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGreen, // Themed title color
                      ),
                    ),
                    subtitle: Text(
                      conv.email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.black87, // Themed subtitle color
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20, // Slightly larger icon
                      color: kAccentGreen, // Themed icon color
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            token: token,
                            receiverId: conv.userId,
                            receiverUsername: conv.username, // Pass username here
                          ),
                        ),
                      );
                    },
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