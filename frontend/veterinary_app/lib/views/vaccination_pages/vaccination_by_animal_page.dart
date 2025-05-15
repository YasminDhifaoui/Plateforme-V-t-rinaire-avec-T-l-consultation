import 'package:flutter/material.dart';
import '../../models/vaccination_models/vaccination_model.dart';
import '../../services/vaccination_services/vaccination_service.dart';
import '../components/home_navbar.dart';

class VaccinationByAnimalPage extends StatefulWidget {
  final String token;
  final String animalId;

  const VaccinationByAnimalPage({
    Key? key,
    required this.token,
    required this.animalId,
  }) : super(key: key);

  @override
  _VaccinationByAnimalPageState createState() => _VaccinationByAnimalPageState();
}

class _VaccinationByAnimalPageState extends State<VaccinationByAnimalPage> {
  late Future<List<VaccinationModel>> _vaccinationFuture;

  @override
  void initState() {
    super.initState();
    _vaccinationFuture = VaccinationService()
        .getVaccinationsByAnimalId(widget.token, widget.animalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar
          HomeNavbar(
            onLogout: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),

          // Return button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Return'),
            ),
          ),

          // Body with vaccination list
          Expanded(
            child: FutureBuilder<List<VaccinationModel>>(
              future: _vaccinationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final vaccinations = snapshot.data ?? [];

                if (vaccinations.isEmpty) {
                  return const Center(
                    child: Text('No vaccinations found for this animal.'),
                  );
                }

                return ListView.builder(
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final vaccine = vaccinations[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.vaccines, color: Colors.green),
                        title: Text(vaccine.name ?? 'Unknown Vaccine'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vaccine.date != null) Text('Date: ${vaccine.date!}'),

                          ],
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
}
