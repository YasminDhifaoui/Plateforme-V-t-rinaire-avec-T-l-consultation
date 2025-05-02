import 'package:flutter/material.dart';
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';
import 'package:veterinary_app/services/consultation_services/consultation_service.dart';

class ConsultationListPage extends StatefulWidget {
  final String token;

  const ConsultationListPage({Key? key, required this.token}) : super(key: key);

  @override
  State<ConsultationListPage> createState() => _ConsultationListPageState();
}

class _ConsultationListPageState extends State<ConsultationListPage> {
  late Future<List<Consultation>> _consultations;

  @override
  void initState() {
    super.initState();
    _consultations = ConsultationService.fetchConsultations(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Consultations')),
      body: FutureBuilder<List<Consultation>>(
        future: _consultations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text('No consultations found'));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final consult = snapshot.data![index];
              return Card(
                child: ListTile(
                  title: Text(
                    'Client: ${consult.clientName} | Animal ID: ${consult.animalId}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${consult.date.toLocal()}'),
                      Text('Diagnostic: ${consult.diagnostic}'),
                      Text('Treatment: ${consult.treatment}'),
                      Text('Prescription: ${consult.prescription}'),
                      Text('Notes: ${consult.notes}'),
                      Text('Document: ${consult.documentPath}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
