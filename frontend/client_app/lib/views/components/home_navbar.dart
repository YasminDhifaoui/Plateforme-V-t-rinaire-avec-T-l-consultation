import 'package:client_app/views/profile_pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/services/auth_services/token_service.dart';

import '../conv_pages/conv_page.dart';
// Import the blue color constants from main.dart or your constants file
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

class HomeNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String username;
  final VoidCallback onLogout;

  const HomeNavbar({
    Key? key,
    this.username = '',
    this.onLogout = _defaultOnLogout,
  }) : super(key: key);

  static void _defaultOnLogout() {}

  @override
  State<HomeNavbar> createState() => _HomeNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeNavbarState extends State<HomeNavbar> {
  String? _jwtToken;
  // Placeholder for unread message count - in a real app, this would be dynamic
  int _unreadMessageCount = 1;

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
    // In a real app, you'd set up a listener here for real-time unread messages
    // For demonstration, let's simulate a change after a few seconds
    // Future.delayed(const Duration(seconds: 5), () {
    //   if (mounted) {
    //     setState(() {
    //       _unreadMessageCount = 0; // Messages read
    //     });
    //   }
    // });
  }

  Future<void> _loadJwtToken() async {
    String? token = await TokenService.getToken();
    setState(() {
      _jwtToken = token;
    });
  }

  // Helper to show SnackBar feedback
  void _showTokenErrorSnackBar(TextTheme textTheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Authentication token not available. Please log in.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: kPrimaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.logout_rounded, size: 28),
        tooltip: 'Logout',
        onPressed: widget.onLogout,
      ),
      title: const Text(''),
      actions: [
        // --- Chat/Messages Icon with Notification Badge ---
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
              tooltip: 'Messages',
              onPressed: () {
                if (_jwtToken != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationsPage(token: _jwtToken!),
                    ),
                  );
                  // Optionally clear badge after navigating
                  // setState(() { _unreadMessageCount = 0; });
                } else {
                  _showTokenErrorSnackBar(textTheme);
                }
              },
            ),
            if (_unreadMessageCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent, // Bright red badge
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5), // White border
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _unreadMessageCount > 9 ? '9+' : _unreadMessageCount.toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),

        // --- Username and Interactive Profile Picture ---
        GestureDetector(
          onTap: () {
            if (_jwtToken != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(jwtToken: _jwtToken!),
                ),
              );
            } else {
              _showTokenErrorSnackBar(textTheme);
            }
          },
          // Using Material and InkWell for a standard ripple effect on tap
          child: Material(
            color: Colors.transparent, // Make Material transparent to show AppBar's color
            child: InkWell(
              borderRadius: BorderRadius.circular(50), // Match container's circular shape
              onTap: () {
                if (_jwtToken != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(jwtToken: _jwtToken!),
                    ),
                  );
                } else {
                  _showTokenErrorSnackBar(textTheme);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 4.0), // Adjust padding for tap area
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.username,
                      style: textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kAccentBlue, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/pet_owner.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}