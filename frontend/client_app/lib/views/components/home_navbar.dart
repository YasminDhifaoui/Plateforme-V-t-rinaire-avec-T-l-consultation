import 'package:flutter/material.dart';
import 'package:client_app/views/profile_pages/profile_page.dart';
import 'package:client_app/services/auth_services/token_service.dart';

import '../conv_pages/conv_page.dart'; // Import your TokenService

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
  _HomeNavbarState createState() => _HomeNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeNavbarState extends State<HomeNavbar> {
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
  }

  Future<void> _loadJwtToken() async {
    String? token = await TokenService.getToken();
    setState(() {
      _jwtToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: widget.onLogout,
      ),
      title: const Text(''),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Messages',
          onPressed: () {
            if (_jwtToken != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationsPage(token: _jwtToken!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token not available')),
              );
            }
          },

        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_jwtToken != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(jwtToken: _jwtToken!),
                        ),
                      );
                    } else {
                      // Optional: Handle if token is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token not available')),
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/pet_owner.png',
                        fit: BoxFit.cover,
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
