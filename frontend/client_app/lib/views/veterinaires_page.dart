import 'package:flutter/material.dart';
import '../services/veterinaire_service.dart';
import '../models/veterinaire.dart';

class VetListPage extends StatelessWidget {
  final VeterinaireService vetService = VeterinaireService();

  VetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Veterinaires')),
      body: FutureBuilder<List<Veterinaire>>(
        future: vetService.getAllVeterinaires(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No veterinaires found."));
          }

          final vets = snapshot.data!;
          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              final vet = vets[index];
              return ListTile(
                title: Text(vet.username),
                subtitle: Text(vet.email),
              );
            },
          );
        },
      ),
    );
  }
}
