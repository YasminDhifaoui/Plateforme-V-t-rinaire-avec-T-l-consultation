import 'package:client_app/views/rendezvous_pages/rendezvous_page.dart';
import 'package:client_app/views/vet_pages/veterinary_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/views/pet_pages/pet_list_page.dart';
import 'package:client_app/views/consultation_pages/consultations_page.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/views/components/home_navbar.dart'; // Assuming this is your custom Navbar

// Import the blue color constants from main.dart
import 'package:client_app/main.dart';

import '../utils/app_colors.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String token;

  const HomePage({Key? key, required this.username,required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      backgroundColor: Colors.grey.shade100, // A very light grey for background
      body: CustomScrollView( // Use CustomScrollView for more flexible scrolling with slivers
        slivers: [
          // --- Welcome Section (SliverToBoxAdapter for fixed height content) ---
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30), // Adjusted padding
              decoration: BoxDecoration(
                color: kPrimaryBlue, // Primary blue background
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)), // More pronounced curve
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15, // Increased blur for softer shadow
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Text(
                    'Welcome back,', // More engaging greeting
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.username, // Your dynamic username
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What would you like to explore today?', // Clearer call to action
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9), // Slightly less opaque
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Navigation Grid (SliverPadding and SliverGrid for a nice layout) ---
          SliverPadding(
            padding: const EdgeInsets.all(20.0), // Padding around the grid
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns for a compact look
                crossAxisSpacing: 15.0, // Space between columns
                mainAxisSpacing: 15.0, // Space between rows
                childAspectRatio: 1.0, // Make items square
              ),
              delegate: SliverChildListDelegate(
                [
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.search, // Using an icon for search
                    title: 'Find a Vet',
                    color: Colors.lightBlue.shade400, // Unique color for this card
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VetListPage(username: widget.username),
                        ),
                      );
                    },
                  ),
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.history_edu, // Icon for consultations
                    title: 'My Consultations',
                    color: Colors.orange.shade400,
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
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.pets, // Icon for pets
                    title: 'Manage My Pets',
                    color: Colors.green.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PetListPage()),
                      );
                    },
                  ),
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.event_note, // Icon for appointments
                    title: 'My Appointments',
                    color: Colors.purple.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RendezvousPage(username: widget.username),
                        ),
                      );
                    },
                  ),
                  // Add more cards here if needed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New helper function for grid-based navigation cards
  Widget _buildGridNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color, // Color for the icon background
    required VoidCallback onTap,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 8, // More prominent shadow for grid cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2), // Splash effect matches card color
        highlightColor: color.withOpacity(0.1), // Highlight effect
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              Container(
                padding: const EdgeInsets.all(15), // Padding around the icon
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15), // Light background for the icon
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40, // Larger icon
                  color: color, // Icon color matches card's theme color
                ),
              ),
              const SizedBox(height: 15), // Space between icon and text
              Text(
                title,
                textAlign: TextAlign.center, // Center text
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.black87, // Darker text for readability
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}