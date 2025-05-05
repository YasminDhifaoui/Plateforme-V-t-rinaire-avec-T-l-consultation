import 'package:flutter/material.dart';
import 'package:veterinary_app/utils/logout_helper.dart';
import 'package:veterinary_app/views/consultation_pages/consultation_page.dart';
import 'package:veterinary_app/views/rendezvous_pages/rendezvous_list_page.dart';
import 'package:veterinary_app/views/animal_pages/animals_list_page.dart';
import 'package:veterinary_app/views/client_pages/clients_list_page.dart'; // <-- Import the client page
import 'package:veterinary_app/views/vaccination_pages/vaccination_list_page.dart'; // <-- Import the vaccination list page
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
    final cardTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey[900],
    );
    final cardIconColor = Colors.blueAccent;

    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                children: [
                  _buildHomeCard(
                    context,
                    icon: Icons.pets,
                    label: 'Animals',
                    onTap: () {
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
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.event,
                    label: 'RDV',
                    onTap: () {
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
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.people,
                    label: 'Clients',
                    onTap: () {
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
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.medical_services,
                    label: 'Consultations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ConsultationListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.vaccines,
                    label: 'Vaccinations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => VaccinationListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required TextStyle textStyle,
    required Color iconColor,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 16),
              Text(label, style: textStyle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
