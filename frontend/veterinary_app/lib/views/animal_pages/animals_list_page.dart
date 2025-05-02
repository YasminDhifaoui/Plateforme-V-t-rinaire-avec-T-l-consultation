import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import '../components/home_navbar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: FutureBuilder<List<AnimalModel>>(
        future: _animalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No animals found for this veterinarian.'),
            );
          } else {
            final animals = snapshot.data!;
            return ListView.builder(
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${animal.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Espece: ${animal.espece}'),
                        Text('Race: ${animal.race}'),
                        Text('Age: ${animal.age}'),
                        Text('Sexe: ${animal.sexe}'),
                        Text('Allergies: ${animal.allergies}'),
                        Text(
                          'Antécédents Médicaux: ${animal.anttecedentsmedicaux}',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context); // Navigates back to the previous page
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Return'),
      ),
    );
  }
}
