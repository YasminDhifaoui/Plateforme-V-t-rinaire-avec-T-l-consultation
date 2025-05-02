import 'package:flutter/material.dart';
import 'package:veterinary_app/utils/logout_helper.dart';
import 'package:veterinary_app/views/consultation_pages/consultation_page.dart';
import 'package:veterinary_app/views/rendezvous_pages/rendezvous_list_page.dart';
import 'package:veterinary_app/views/animal_pages/animals_list_page.dart';
import 'package:veterinary_app/views/client_pages/clients_list_page.dart'; // <-- Import the client page
import 'components/home_navbar.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String token;

  const HomePage({super.key, required this.username, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),

            // Animals Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AnimalsListPage(
                          token: widget.token,
                          username: widget.username,
                        ),
                  ),
                );
              },
              child: const Text('View Animals List'),
            ),
            const SizedBox(height: 20),

            // RDV Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RendezVousListPage(
                          token: widget.token,
                          username: widget.username,
                        ),
                  ),
                );
              },
              child: const Text('View RDV List'),
            ),
            const SizedBox(height: 20),

            // Clients Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ClientsListPage(
                          token: widget.token,
                          username: widget.username,
                        ),
                  ),
                );
              },
              child: const Text('View Clients List'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ConsultationListPage(token: widget.token),
                  ),
                );
              },
              child: const Text('View Consultations'),
            ),
          ],
        ),
      ),
    );
  }
}
