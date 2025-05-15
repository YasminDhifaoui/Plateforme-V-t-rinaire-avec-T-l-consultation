import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import '../../services/animal_services/animals_vet_service.dart';
import '../components/home_navbar.dart';
import '../vaccination_pages/vaccination_by_animal_page.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.clientId != '0' && widget.clientId.isNotEmpty) {
      _animalsFuture = AnimalsVetService()
          .getAnimalsByClientId(widget.token, widget.clientId);
    } else {
      _animalsFuture = Future.error('Invalid client ID');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Home Navbar
          HomeNavbar(
            onLogout: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          // Return Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Return'),
            ),
          ),
          // Animal List
          Expanded(
            child: FutureBuilder<List<AnimalModel>>(
              future: _animalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final animals = snapshot.data ?? [];

                if (animals.isEmpty) {
                  return const Center(child: Text('No animals found for this client.'));
                }

                return ListView.builder(
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];

                    if (animal.ownerId == widget.clientId) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal.name ?? 'Unknown Name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Species: ${animal.espece ?? 'N/A'}'),
                              Text('Race: ${animal.race ?? 'N/A'}'),
                              Text('Sexe: ${animal.sexe ?? 'N/A'}'),
                              Text('Age: ${animal.age?.toString() ?? 'N/A'}'),
                              Text('Allergies: ${animal.allergies ?? 'N/A'}'),
                              Text('Antécédents médicaux: ${animal.anttecedentsmedicaux ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VaccinationByAnimalPage(
                                          token: widget.token,
                                          animalId: animal.id ?? '',
                                        ),
                                      ),
                                    );
                                  },

                                  icon: const Icon(Icons.vaccines),
                                  label: const Text('Vaccination'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container(); // Skip animals not matching client ID
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
