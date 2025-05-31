import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart';

// Import the new edit page
import '../../utils/app_colors.dart';
import 'animal_edit_page.dart';

// Import the VaccinationByAnimalPage
import 'package:veterinary_app/views/vaccination_pages/vaccination_by_animal_page.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<AnimalModel> _allAnimals = [];
  List<AnimalModel> _filteredAnimals = [];

  @override
  void initState() {
    super.initState();
    _refreshAnimalsList();
    _searchController.addListener(_filterAnimals);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAnimals);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAnimalsList() {
    setState(() {
      _animalsFuture = _service.getAnimalsList(widget.token).then((animals) {
        _allAnimals = animals;
        _filterAnimals();
        return animals;
      }).catchError((error) {
        _allAnimals = [];
        _filteredAnimals = [];
        throw error;
      });
    });
  }

  void _filterAnimals() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnimals = _allAnimals.where((animal) {
        return animal.name.toLowerCase().contains(query) ||
            animal.espece.toLowerCase().contains(query) ||
            animal.race.toLowerCase().contains(query) ||
            animal.ownerUsername.toLowerCase().contains(query);
      }).toList();
    });
  }

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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search animals by name, species, breed or owner...',
                prefixIcon: Icon(Icons.search, color: kPrimaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    _filterAnimals();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AnimalModel>>(
              future: _animalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
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
                            onPressed: _refreshAnimalsList,
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
                } else if (_filteredAnimals.isEmpty && _searchController.text.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: kAccentGreen,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No animals found matching "${_searchController.text}".',
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            _filterAnimals();
                          },
                          icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                          label: Text('Clear Search', style: textTheme.labelLarge),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (_filteredAnimals.isEmpty && _searchController.text.isEmpty && _allAnimals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets_rounded,
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
                        ElevatedButton.icon(
                          onPressed: () {
                            _showSnackBar('Add new animal feature coming soon!', isSuccess: true);
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                          label: Text('Add New Animal', style: textTheme.labelLarge),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredAnimals.length,
                    itemBuilder: (context, index) {
                      final animal = _filteredAnimals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_rounded, color: kPrimaryGreen, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Name: ${animal.name}',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 0.8, color: Colors.grey),
                              _buildAnimalInfoRow(textTheme, Icons.category_rounded, 'Species', animal.espece),
                              _buildAnimalInfoRow(textTheme, Icons.person_rounded, 'Owner', animal.ownerUsername),
                              _buildAnimalInfoRow(textTheme, Icons.pets_rounded, 'Breed', animal.race),
                              _buildAnimalInfoRow(textTheme, Icons.cake_rounded, 'Age', '${animal.age} years'),
                              _buildAnimalInfoRow(textTheme, Icons.transgender_rounded, 'Gender', animal.sexe),
                              _buildAnimalInfoRow(textTheme, Icons.warning_rounded, 'Allergies', animal.allergies.isEmpty ? 'None' : animal.allergies),
                              _buildAnimalInfoRow(textTheme, Icons.history_edu_rounded, 'Medical History', animal.anttecedentsmedicaux.isEmpty ? 'None' : animal.anttecedentsmedicaux),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VaccinationByAnimalPage(
                                            animalId: animal.id,
                                            token: widget.token,
                                            animalName: animal.name, // <--- ADDED THIS LINE
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.vaccines_rounded, color: Colors.white),
                                    label: Text('Vaccines', style: textTheme.labelSmall?.copyWith(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kAccentGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AnimalEditPage(
                                            animal: animal,
                                            jwtToken: widget.token,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _refreshAnimalsList();
                                      }
                                    },
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                                    label: Text('Update', style: textTheme.labelSmall?.copyWith(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kAccentGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
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
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        label: Text('Return', style: Theme.of(context).textTheme.labelLarge),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

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
              value,
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