import 'package:flutter/material.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/views/profile_pages/profile_page.dart';

// Removed: import '../../services/notification_handle/message_notifier.dart';
import '../../utils/app_colors.dart';
import '../conv_pages/conv_page.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class HomeNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String username;
  final VoidCallback onLogout;

  const HomeNavbar({
    super.key,
    this.username = '',
    this.onLogout = _defaultOnLogout,
  });

  static void _defaultOnLogout() {}

  @override
  _HomeNavbarState createState() => _HomeNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeNavbarState extends State<HomeNavbar> {
  String? _jwtToken;
  // Removed: int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
    // Removed: unreadMessageNotifier.addListener(_updateUnreadMessageCount);
  }

  @override
  void dispose() {
    // Removed: unreadMessageNotifier.removeListener(_updateUnreadMessageCount);
    super.dispose();
  }

  // Removed: void _updateUnreadMessageCount() { ... }

  Future<void> _loadJwtToken() async {
    String? token = await TokenService.getToken();
    setState(() {
      _jwtToken = token;
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
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: kPrimaryGreen, // Use primary green from theme
      foregroundColor: Colors.white, // White icons and text on app bar
      elevation: 4, // Add a subtle shadow for depth
      shadowColor: Colors.black.withOpacity(0.2), // Darker shadow for green theme

      leading: IconButton(
        icon: const Icon(Icons.logout_rounded), // Modern logout icon
        onPressed: widget.onLogout,
        tooltip: 'Logout',
        color: Colors.white, // Ensure icon is white
      ),

      actions: [
        // Messages/Chat Icon (Badge removed)
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white), // Modern chat icon, white
          tooltip: 'Messages',
          onPressed: () {
            if (_jwtToken != null) {
              // Removed: unreadMessageNotifier.value = 0; // Reset count on opening chat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationsPage(token: _jwtToken!),
                ),
              );
            } else {
              _showSnackBar('Authentication token not available. Please log in.', isSuccess: false);
            }
          },
        ),

        // User Profile Section (Username + Profile Picture)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white), // Themed titleMedium for username
                ),
                const SizedBox(width: 10), // Increased spacing
                GestureDetector(
                  onTap: () {
                    if (_jwtToken != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VetProfilePage(), // Navigate to VetProfilePage
                        ),
                      );
                    } else {
                      _showSnackBar('Authentication token not available. Please log in.', isSuccess: false);
                    }
                  },
                  child: Container(
                    width: 40, // Slightly larger profile picture container
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5), // Thicker white border
                      boxShadow: [ // Subtle shadow for the profile picture
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/doctor.png', // Ensure this asset path is correct
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if image fails to load
                          return Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: Colors.grey.shade400,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}