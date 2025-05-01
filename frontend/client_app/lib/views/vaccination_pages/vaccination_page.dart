import 'package:client_app/models/vaccination_models/vaccination.dart';
import 'package:client_app/services/vaccination_services/vaccination_service.dart';
import 'package:flutter/material.dart';
import 'package:client_app/views/components/home_navbar.dart';
import 'package:client_app/utils/logout_helper.dart';

class VaccinationPage extends StatelessWidget {
  final String animalId;
  final String animalName;
  final String username;

  const VaccinationPage({
    Key? key,
    required this.animalId,
    required this.animalName,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = VaccinationService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: HomeNavbar(
        username: username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shadowColor: Colors.grey.withOpacity(0.3),
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return'),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${animalName}\'s Vaccination History',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.teal[800],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vaccination List
          Expanded(
            child: FutureBuilder<List<Vaccination>>(
              future: service.getVaccinationsForAnimal(animalId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No vaccinations found.',
                        style: TextStyle(fontSize: 16)),
                  );
                }

                final vaccinations = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final vac = vaccinations[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green[100],
                          child:
                              const Icon(Icons.vaccines, color: Colors.green),
                        ),
                        title: Text(
                          vac.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Date: ${vac.date.toLocal().toString().split(".")[0]}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Add any action if needed
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(vac.name),
                              content: Text(
                                  'Vaccination date: ${vac.date.toLocal().toString().split(".")[0]}'),
                              actions: [
                                TextButton(
                                  child: const Text("Close"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
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
    );
  }
}
