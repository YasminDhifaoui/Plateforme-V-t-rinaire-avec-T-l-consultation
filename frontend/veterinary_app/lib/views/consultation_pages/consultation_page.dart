import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';
import 'package:veterinary_app/services/consultation_services/consultation_service.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veterinary_app/views/consultation_pages/add_consultation_page.dart';
import 'package:veterinary_app/views/consultation_pages/update_consultation_page.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';

class ConsultationListPage extends StatefulWidget {
  final String token;
  final String username;

  const ConsultationListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<ConsultationListPage> createState() => _ConsultationListPageState();
}

class _ConsultationListPageState extends State<ConsultationListPage> {
  late Future<List<Consultation>> _consultations;
  List<AnimalModel> _animals = [];
  bool _isLoadingAnimals = false;
  List<ClientModel> _clients = [];
  bool _isLoadingClients = false;

  @override
  void initState() {
    super.initState();
    _consultations = ConsultationService.fetchConsultations(widget.token);
    _fetchAnimals();
    _fetchClients();
  }

  Future<void> _fetchAnimals() async {
    setState(() {
      _isLoadingAnimals = true;
    });
    try {
      final animals = await AnimalsVetService().getAnimalsList(widget.token);
      setState(() {
        _animals = animals;
      });
    } catch (e) {
      // Handle error, optionally show a message
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load animals: \$e')));
      }
    } finally {
      setState(() {
        _isLoadingAnimals = false;
      });
    }
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoadingClients = true;
    });
    try {
      final clients = await ClientService().getAllClients(widget.token);
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load clients: \$e')));
      }
    } finally {
      setState(() {
        _isLoadingClients = false;
      });
    }
  }

  void _showAnimalDetails(String animalName) {
    final animal = _animals.firstWhere(
      (a) => a.name == animalName,
      orElse:
          () => AnimalModel(
            id: '',
            name: 'Unknown',
            espece: '',
            race: '',
            age: 0,
            sexe: '',
            allergies: '',
            anttecedentsmedicaux: '',
            ownerId: '',
          ),
    );

    if (animal.id == '') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal details not found')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Animal Details: ${animal.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Species: ${animal.espece}'),
                Text('Breed: ${animal.race}'),
                Text('Age: ${animal.age}'),
                Text('Sex: ${animal.sexe}'),
                Text('Allergies: ${animal.allergies}'),
                Text('Medical History: ${animal.anttecedentsmedicaux}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showClientDetails(String clientName) {
    final client = _clients.firstWhere(
      (c) => c.username == clientName,
      orElse:
          () => ClientModel(
            username: 'Unknown',
            email: '',
            phoneNumber: '',
            address: '',
          ),
    );

    if (client.username == 'Unknown') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client details not found')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Client Details: ${client.username}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Email: ${client.email}'),
                Text('Phone: ${client.phoneNumber}'),
                Text('Address: ${client.address}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  Future<void> _downloadDocument(String urlString) async {
    final Uri url = Uri.parse("http://10.0.2.2:5000/$urlString");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document.')),
        );
      }
    }
  }

  void _showConsultationDetails(Consultation consult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Consultation Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Client: ${consult.clientName}'),
                Text('Animal: ${consult.animalName}'),
                Text('Date: ${formatDate(consult.date)}'),
                Text('Diagnostic: ${consult.diagnostic}'),
                Text('Treatment: ${consult.treatment}'),
                Text('Prescription: ${consult.prescription}'),
                Text('Notes: ${consult.notes}'),
                Text('Document: ${consult.documentPath}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Consultation>>(
              future: _consultations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No consultations found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final consult = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(
                            'Client: ${consult.clientName} | Animal: ${consult.animalName}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text('Date: ${formatDate(consult.date)}'),
                              Text('Diagnostic: ${consult.diagnostic}'),
                              Text('Treatment: ${consult.treatment}'),
                              Text('Prescription: ${consult.prescription}'),
                              Text('Notes: ${consult.notes}'),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Document: '),
                                  Flexible(
                                    child: Text(
                                      consult.documentPath,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed:
                                        () => _downloadDocument(
                                          consult.documentPath,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'see_animal':
                                  _showAnimalDetails(consult.animalName);
                                  break;
                                case 'see_client':
                                  _showClientDetails(consult.clientName);
                                  break;
                                case 'see_doc':
                                  _downloadDocument(consult.documentPath);
                                  break;
                                case 'update':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => UpdateConsultationPage(
                                            token: widget.token,
                                            username: widget.username,
                                            consultation: consult,
                                          ),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      setState(() {
                                        _consultations =
                                            ConsultationService.fetchConsultations(
                                              widget.token,
                                            );
                                      });
                                    }
                                  });
                                  break;
                                case 'delete':
                                  // TODO: implement delete logic
                                  break;
                                case 'details':
                                  _showConsultationDetails(consult);
                                  break;
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'see_animal',
                                    child: Text('See Animal'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'see_client',
                                    child: Text('See Client'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'see_doc',
                                    child: Text('See Document'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'update',
                                    child: Text('Update'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Text('Details'),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddConsultationPage(
                    token: widget.token,
                    username: widget.username,
                  ),
            ),
          );
        },
        tooltip: 'Add Consultation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
