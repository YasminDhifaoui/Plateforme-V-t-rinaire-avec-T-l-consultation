import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import '../components/home_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class AnimalsListPage extends StatefulWidget {
  final String token;
  final String username;

  const AnimalsListPage({super.key, required this.token, required this.username});

  @override
  _AnimalsListPageState createState() => _AnimalsListPageState();
}

class _AnimalsListPageState extends State<AnimalsListPage> {
  late Future<List<AnimalModel>> _animalsFuture;
  final AnimalsVetService _service = AnimalsVetService();

  @override
  void initState() {
    super.initState();
    _animalsFuture = _service.getAnimalsList(widget.token);
  }

  // Method to refresh the animal list
  void _refreshAnimalsList() {
    setState(() {
      _animalsFuture = _service.getAnimalsList(widget.token);
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          // This logout action should typically be handled by a global logout helper
          // that navigates to the login page and clears tokens.
          // Assuming LogoutHelper.handleLogout is called elsewhere for full logout.
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: FutureBuilder<List<AnimalModel>>(
        future: _animalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kPrimaryGreen), // Themed loading indicator
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded, // Error icon
                      color: Colors.red.shade400,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load animals: ${snapshot.error}',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshAnimalsList, // Retry button
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: Text('Retry', style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_rounded, // Engaging icon for no animals
                    color: kAccentGreen,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No animals found!',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a new animal to get started.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            final animals = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0), // Consistent padding
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return Card(
                  // Card styling is handled by CardThemeData in main.dart
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8, // Adjusted horizontal margin
                    vertical: 8, // Adjusted vertical margin
                  ),
                  elevation: 8, // More pronounced shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18), // More rounded corners
                  ),
                  child: InkWell( // Added InkWell for tap feedback
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      // TODO: Implement navigation to animal detail page or edit page
                      _showSnackBar('Tapped on ${animal.name}', isSuccess: true);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Increased padding inside card
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge_rounded, color: kPrimaryGreen, size: 24), // Icon for name
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Name: ${animal.name}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryGreen, // Themed title color
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 0.8, color: Colors.grey), // Themed divider
                          _buildAnimalInfoRow(textTheme, Icons.category_rounded, 'Species', animal.espece),
                          _buildAnimalInfoRow(textTheme, Icons.pets_rounded, 'Breed', animal.race),
                          _buildAnimalInfoRow(textTheme, Icons.cake_rounded, 'Age', '${animal.age} years'),
                          _buildAnimalInfoRow(textTheme, Icons.transgender_rounded, 'Gender', animal.sexe),
                          _buildAnimalInfoRow(textTheme, Icons.warning_rounded, 'Allergies', animal.allergies.isEmpty ? 'None' : animal.allergies),
                          _buildAnimalInfoRow(textTheme, Icons.history_edu_rounded, 'Medical History', animal.anttecedentsmedicaux.isEmpty ? 'None' : animal.anttecedentsmedicaux),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context); // Navigates back to the previous page
        },
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), // Modern back icon
        label: Text('Return', style: Theme.of(context).textTheme.labelLarge), // Themed label style
        backgroundColor: kPrimaryGreen, // Themed background color
        foregroundColor: Colors.white, // White icon and text
        elevation: 6, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded shape
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Center the FAB
    );
  }

  // Helper widget to build consistent info rows
  Widget _buildAnimalInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Adjusted vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccentGreen), // Themed icon
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow text to wrap if long
            ),
          ),
        ],
      ),
    );
  }
}