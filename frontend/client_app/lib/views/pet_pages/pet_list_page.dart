import 'package:client_app/views/vaccination_pages/vaccination_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/animals_models/animal.dart';
import '../../services/animal_services/animal_service.dart';
import '../../utils/logout_helper.dart'; // Keep if you use this for general logout logic
import '../../services/animal_services/animal_delete_service.dart';
// import '../components/home_navbar.dart'; // Replaced with standard AppBar for this page
import 'add_pet_page.dart';
import 'update_pet_page.dart';
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

class PetListPage extends StatefulWidget {
  const PetListPage({Key? key}) : super(key: key);

  @override
  State<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  String _username = ''; // Renamed to _username for consistency
  final AnimalService animalService = AnimalService();
  final AnimalDeleteService animalDeleteService = AnimalDeleteService();
  late Future<List<Animal>> _initialAnimalsFuture; // Future for initial fetch
  final TextEditingController _searchController = TextEditingController();

  List<Animal> _allAnimals = []; // Stores the full list of animals
  List<Animal> _filteredAnimals = []; // Stores the currently filtered list

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initialAnimalsFuture = _fetchInitialAnimals(); // Start fetching animals
    _searchController.addListener(_filterAnimals); // Listen for search input changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAnimals);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<List<Animal>> _fetchInitialAnimals() async {
    try {
      final animals = await animalService.getAnimalsList();
      setState(() {
        _allAnimals = animals;
        _filterAnimals(); // Apply initial filter (which is no filter if search is empty)
      });
      return animals;
    } catch (e) {
      _showSnackBar("Failed to load pets. Please try again.", isSuccess: false);
      rethrow; // Rethrow to let FutureBuilder handle error state
    }
  }

  void _filterAnimals() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnimals = _allAnimals.where((animal) {
        return animal.name.toLowerCase().contains(query) ||
            animal.espece.toLowerCase().contains(query) ||
            animal.race.toLowerCase().contains(query) ||
            animal.sexe.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _refreshAnimals() async {
    setState(() {
      _initialAnimalsFuture = _fetchInitialAnimals(); // Re-fetch all animals
      _searchController.clear(); // Clear search on refresh
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
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Helper for info rows in pet details dialog
  Widget _buildInfoRow(TextTheme textTheme, String label, String value) {
    if (value.isEmpty || value == 'N/A') { // Handle 'N/A' as well
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryBlue),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Manage My Pets', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pets by name, species, or breed...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                prefixIcon: Icon(Icons.search, color: kPrimaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    _filterAnimals(); // Clear filter
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              ),
              style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
              cursorColor: kPrimaryBlue,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Animal>>(
              future: _initialAnimalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            "Failed to load pets: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _refreshAnimals, // Retry fetching the pets
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Retry', style: textTheme.labelLarge),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_allAnimals.isEmpty) { // No pets found at all
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_rounded, color: Colors.grey.shade400, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          "You haven't added any pets yet.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddPetPage()),
                            );
                            _refreshAnimals(); // Refresh after adding a new pet
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Add Your First Pet', style: textTheme.labelLarge),
                        ),
                      ],
                    ),
                  );
                } else if (_filteredAnimals.isEmpty && _searchController.text.isNotEmpty) {
                  // No pets matching search query
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 80), // No search results icon
                        const SizedBox(height: 16),
                        Text(
                          "No pets match your search.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Try a different name or breed.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  itemCount: _filteredAnimals.length, // Use filtered list
                  itemBuilder: (context, index) {
                    final animal = _filteredAnimals[index]; // Use filtered animal
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: InkWell( // Added InkWell for ripple effect on tap
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          _showPetDetailsDialog(context, animal, textTheme); // Show detailed dialog
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kAccentBlue, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Icon(Icons.pets, size: 30, color: kPrimaryBlue), // Themed pet icon
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animal.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${animal.espece} - ${animal.race}',
                                      style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                                    ),
                                    Text(
                                      'Age: ${animal.age} | Sex: ${animal.sexe}',
                                      style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Row( // Trailing actions for each pet
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded, color: kAccentBlue), // Themed edit icon
                                    tooltip: 'Edit Pet',
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UpdatePetPage(animal: animal),
                                        ),
                                      );
                                      if (result == true) {
                                        _refreshAnimals();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_rounded, color: Colors.red.shade400), // Themed delete icon
                                    tooltip: 'Delete Pet',
                                    onPressed: () => _confirmDelete(context, animal), // Use themed dialog
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.vaccines_rounded, color: Colors.green.shade400), // Themed vaccines icon
                                    tooltip: 'View Vaccinations',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VaccinationPage(
                                            animalId: animal.id,
                                            animalName: animal.name,
                                            username: _username,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetPage()),
          );
          _refreshAnimals(); // Refresh after adding a new pet
        },
        backgroundColor: kPrimaryBlue, // Themed FAB
        foregroundColor: Colors.white, // White icon
        child: const Icon(Icons.add_rounded), // Modern add icon
        tooltip: 'Add New Pet',
      ),
    );
  }

  // Custom confirmation dialog for delete
  Future<void> _confirmDelete(BuildContext context, Animal animal) async {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange.shade400, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Confirm Deletion',
                  style: textTheme.headlineSmall?.copyWith(color: kPrimaryBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete ${animal.name}? This action cannot be undone.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          side: const BorderSide(color: kPrimaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600, // Red for delete action
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                        ),
                        child: Text('Delete', style: textTheme.labelLarge),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        await animalDeleteService.deleteAnimal(animal.id);
        _showSnackBar('${animal.name} deleted successfully', isSuccess: true);
        _refreshAnimals();
      } catch (e) {
        _showSnackBar('Failed to delete ${animal.name}: $e', isSuccess: false);
      }
    }
  }

  // Custom dialog for pet details
  void _showPetDetailsDialog(BuildContext context, Animal animal, TextTheme textTheme) {
    final antecedents = animal.antecedentsmedicaux.trim();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets_rounded, color: kPrimaryBlue, size: 40),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        animal.name,
                        style: textTheme.headlineSmall?.copyWith(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Expanded( // Use Expanded to allow ListView to take available height
                  child: ListView(
                    shrinkWrap: true, // Important for ListView inside Column
                    children: [
                      _buildInfoRow(textTheme, 'Species', animal.espece),
                      _buildInfoRow(textTheme, 'Breed', animal.race),
                      _buildInfoRow(textTheme, 'Age', animal.age.toString()),
                      _buildInfoRow(textTheme, 'Sex', animal.sexe),
                      _buildInfoRow(textTheme, 'Allergies', animal.allergies),
                      _buildInfoRow(textTheme, 'Medical History', antecedents.isNotEmpty ? antecedents : 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: Text('Close', style: textTheme.labelLarge),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}