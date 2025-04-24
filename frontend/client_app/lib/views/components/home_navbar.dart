import 'package:flutter/material.dart';

class HomeNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final VoidCallback onLogout;

  const HomeNavbar({Key? key, this.username = '', this.onLogout = _defaultOnLogout})
      : super(key: key);

  static void _defaultOnLogout() {}

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: onLogout,
      ),
      title: const Text(''),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
