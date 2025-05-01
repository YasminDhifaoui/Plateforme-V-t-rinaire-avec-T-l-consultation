import 'package:client_app/views/vaccination_pages/vaccination_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/animals_models/animal.dart';
import '../../services/animal_services/animal_service.dart';
import '../../utils/logout_helper.dart';
import '../../services/animal_services/animal_delete_service.dart';
import '../components/home_navbar.dart';
import 'add_pet_page.dart';
import 'update_pet_page.dart';

class PetListPage extends StatefulWidget {
  const PetListPage({Key? key}) : super(key: key);

  @override
  State<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  String username = '';
  final AnimalService animalService = AnimalService();
  final AnimalDeleteService animalDeleteService = AnimalDeleteService();
  late Future<List<Animal>> _animalsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animalsFuture = animalService.getAnimalsList();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _refreshAnimals() async {
    setState(() {
      _animalsFuture = animalService.getAnimalsList();
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Back to Home',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Animal>>(
              future: _animalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No pets found.'));
                }

                final animals = snapshot.data!;
                return ListView.builder(
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: const CircleAvatar(
                          child: Icon(Icons.pets),
                        ),
                        title: Text(
                          animal.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Espece: ${animal.espece}'),
                            Text('Race: ${animal.race}'),
                            Text('Age: ${animal.age}'),
                            Text('Sexe: ${animal.sexe}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdatePetPage(animal: animal),
                                  ),
                                );
                                if (result == true) {
                                  _refreshAnimals();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text(
                                          'Are you sure you want to delete ${animal.name}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await animalDeleteService
                                        .deleteAnimal(animal.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${animal.name} deleted successfully')),
                                    );
                                    _refreshAnimals();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to delete ${animal.name}: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.vaccines,
                                  color: Colors.green),
                              tooltip: 'View Vaccinations',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VaccinationPage(
                                      animalId: animal.id,
                                      animalName: animal.name,
                                      username: username,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final antecedents =
                                  animal.antecedentsmedicaux.trim();
                              return AlertDialog(
                                title: Text(animal.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22)),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: [
                                          _buildInfoRow(
                                              'Espece', animal.espece),
                                          const Divider(),
                                          _buildInfoRow('Race', animal.race),
                                          const Divider(),
                                          _buildInfoRow(
                                              'Age', animal.age.toString()),
                                          const Divider(),
                                          _buildInfoRow('Sexe', animal.sexe),
                                          const Divider(),
                                          _buildInfoRow(
                                              'Allergies', animal.allergies),
                                          const Divider(),
                                          _buildInfoRow(
                                            'Antécédents Médicaux',
                                            antecedents.isNotEmpty
                                                ? antecedents
                                                : 'N/A',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
          _refreshAnimals();
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Pet',
      ),
    );
  }
}
