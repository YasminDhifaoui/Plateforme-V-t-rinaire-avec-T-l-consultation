import 'package:client_app/views/rendezvous_pages/rendezvous_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/views/vet_pages/veterinary_page.dart';
import 'package:client_app/views/pet_pages/pet_list_page.dart';
import 'package:client_app/views/consultation_pages/consultations_page.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/views/components/home_navbar.dart'; // Assuming this is your custom Navbar

// Import the blue color constants from main.dart
import 'package:client_app/main.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Helper function to build a consistent navigation card
  Widget _buildNavigationCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    IconData? icon, // Optional icon if you prefer icons over images for some items
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 6, // Subtle shadow for a lifted effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0), // Margin around each card
      child: InkWell( // Provides visual feedback on tap
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Image.asset or Icon based on availability
              imagePath.isNotEmpty
                  ? Image.asset(
                imagePath,
                width: 50, // Slightly larger image
                height: 50,
              )
                  : (icon != null
                  ? Icon(icon, size: 50, color: kAccentBlue) // Default icon color
                  : const SizedBox.shrink()), // Fallback if neither is provided
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: kPrimaryBlue, // Blue title for consistency
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_ios, // Modern arrow icon
                color: kPrimaryBlue, // Blue arrow
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Assuming HomeNavbar is a custom widget. Ensure its styling matches the app's theme (blue background, white text).
      // If HomeNavbar cannot be styled externally, consider replacing it with a standard AppBar here.
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Welcome Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: kPrimaryBlue, // Blue background for welcome section
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Hello, ${widget.username}!', // Personalized welcome
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What would you like to do today?',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Spacing after welcome section

            // --- Navigation Cards ---
            _buildNavigationCard(
              context: context,
              imagePath: 'assets/images/veterinary.png',
              title: 'Look for a Veterinary',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VetListPage(username: widget.username),
                  ),
                );
              },
            ),
            _buildNavigationCard(
              context: context,
              imagePath: 'assets/images/consultation.png',
              title: 'See My Consultations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultationsPage(
                      username: widget.username,
                    ),
                  ),
                );
              },
            ),
            _buildNavigationCard(
              context: context,
              imagePath: 'assets/images/pet_owner.png',
              title: 'Manage My Pets',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PetListPage()),
                );
              },
            ),
            _buildNavigationCard(
              context: context,
              imagePath: 'assets/images/apointment.png',
              title: 'My Appointments', // Changed from Rendezvous for clarity
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RendezvousPage(username: widget.username),
                  ),
                );
              },
            ),
            const SizedBox(height: 30), // Spacing at the bottom
          ],
        ),
      ),
    );
  }
}