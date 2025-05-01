import 'package:flutter/material.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/views/profile_pages/profile_page.dart';

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
      backgroundColor: Colors.green.shade700, // Green theme
      leading: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: widget.onLogout,
        tooltip: 'Logout',
      ),
      title: const Text(
        'Veterinary App',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_jwtToken != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VetProfilePage(),
                        ),
                      );
                    } else {
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
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/doctor.png',
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
