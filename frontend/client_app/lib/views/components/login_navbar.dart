import 'package:client_app/main.dart';
import 'package:flutter/material.dart';

class LoginNavbar extends StatelessWidget implements PreferredSizeWidget {
  const LoginNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          const Color(0xFF003366), // Marine blue (same as main navbar)
      title: GestureDetector(
        /*onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
          );
        },*/
        child: Image.asset('assets/images/app_logo.png', height: 40),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
