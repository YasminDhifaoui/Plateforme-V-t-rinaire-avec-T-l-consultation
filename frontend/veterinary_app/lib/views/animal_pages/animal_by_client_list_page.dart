import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import '../../services/animal_services/animals_vet_service.dart';
import '../components/home_navbar.dart';
import '../vaccination_pages/vaccination_by_animal_page.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class AnimalByClientListPage extends StatefulWidget {
  final String clientId;
  final String token;

  const AnimalByClientListPage({
    Key? key,
    required this.clientId,
    required this.token,
  }) : super(key: key);

  @override
  _AnimalByClientListPageState createState() => _AnimalByClientListPageState();
}

class _AnimalByClientListPageState extends State<AnimalByClientListPage> {
  late Future<List<AnimalModel>> _animalsFuture;
  final AnimalsVetService _service = AnimalsVetService();

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  // Method to fetch animals
  void _fetchAnimals() {
    if (widget.clientId != '0' && widget.clientId.isNotEmpty) {
      _animalsFuture =
          _service.getAnimalsByClientId(widget.token, widget.clientId);
    } else {
      _animalsFuture = Future.error('Invalid client ID provided.');
    }
  }

  // Method to refresh the animal list
  void _refreshAnimalsList() {
    setState(() {
      _fetchAnimals(); // Re-trigger the future
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
        // HomeNavbar doesn't have a direct 'title' property for this page.
        // If you need a specific title for this page, you'd add it to HomeNavbar
        // or replace HomeNavbar with a standard AppBar here.
        // For now, it will use the default title logic within HomeNavbar.
        username: '', // Username might not be directly relevant for this specific navbar instance
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Return Button (styled consistently with other list pages)
          Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Align( // Align the button to the start
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), // Modern back icon
                label: Text('Return', style: textTheme.labelLarge), // Themed label style
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen, // Themed background color
                  foregroundColor: Colors.white, // White icon and text
                  elevation: 6, // Add elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded shape
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Adjusted padding
                ),
              ),
            ),
          ),
          // Animal List
          Expanded(
            child: FutureBuilder<List<AnimalModel>>(
              future: _animalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryGreen)); // Themed loading indicator
                }

                if (snapshot.hasError) {
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
                            style: textTheme.bodyLarge
                                ?.copyWith(color: Colors.red.shade700),
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
                }

                final animals = snapshot.data ?? [];

                // Optimization: Filter animals here if the service returns all animals
                // and you only want those for the specific client.
                // However, the service `getAnimalsByClientId` implies it already filters.
                // If it doesn't, uncomment and use the filtered list:
                // final filteredAnimals = animals.where((animal) => animal.ownerId == widget.clientId).toList();

                if (animals.isEmpty) { // Using 'animals' directly assuming service filters
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
                          'No animals found for this client.',
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The client has not registered any animals yet.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Consistent padding
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];

                    // Removed the `if (animal.ownerId == widget.clientId)` check here
                    // assuming `getAnimalsByClientId` already handles filtering.
                    // If not, it's better to filter the list *before* ListView.builder
                    // to avoid building empty Containers.

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8), // Adjusted margin
                      elevation: 8, // More pronounced shadow
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(18), // More rounded corners
                      ),
                      child: InkWell(
                        // Added InkWell for tap feedback
                        borderRadius: BorderRadius.circular(18),

                        child: Padding(
                          padding: const EdgeInsets.all(20.0), // Increased padding inside card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_rounded,
                                      color: kPrimaryGreen, size: 24), // Icon for name
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Name: ${animal.name ?? 'Unknown Name'}',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen, // Themed title color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                  height: 20,
                                  thickness: 0.8,
                                  color: Colors.grey), // Themed divider
                              _buildAnimalInfoRow(textTheme, Icons.category_rounded, 'Species', animal.espece),
                              _buildAnimalInfoRow(textTheme, Icons.pets_rounded, 'Breed', animal.race),
                              _buildAnimalInfoRow(textTheme, Icons.cake_rounded, 'Age', '${animal.age?.toString() ?? 'N/A'} years'),
                              _buildAnimalInfoRow(textTheme, Icons.transgender_rounded, 'Gender', animal.sexe),
                              _buildAnimalInfoRow(textTheme, Icons.warning_rounded, 'Allergies', animal.allergies.isEmpty ? 'None' : animal.allergies),
                              _buildAnimalInfoRow(textTheme, Icons.history_edu_rounded, 'Medical History', animal.anttecedentsmedicaux.isEmpty ? 'None' : animal.anttecedentsmedicaux),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VaccinationByAnimalPage(
                                              token: widget.token,
                                              animalId: animal.id ?? '',
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.vaccines_rounded, color: Colors.white), // Themed icon
                                  label: Text('View Vaccinations', style: textTheme.labelLarge), // Themed label
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAccentGreen, // Use accent green for actions
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent info rows
  Widget _buildAnimalInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccentGreen),
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
              value.isEmpty ? 'N/A' : value, // Handle empty values gracefully
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}