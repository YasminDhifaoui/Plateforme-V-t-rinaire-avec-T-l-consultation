import 'package:flutter/material.dart';
import 'package:veterinary_app/models/vaccination_models/vaccination_model.dart';
import 'package:veterinary_app/services/vaccination_services/vaccination_service.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import '../components/home_navbar.dart';

class VaccinationListPage extends StatefulWidget {
  final String token;
  final String username;

  const VaccinationListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  _VaccinationListPageState createState() => _VaccinationListPageState();
}

class _VaccinationListPageState extends State<VaccinationListPage> {
  late Future<List<VaccinationModel>> _vaccinationsFuture;
  final VaccinationService _service = VaccinationService();
  late Future<List<AnimalModel>> _animalsFuture;
  late Future<List<ClientModel>> _clientsFuture;
  String? _selectedAnimalId;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vaccinationsFuture = _service.getAllVaccinations(widget.token);
    _animalsFuture = AnimalsVetService().getAnimalsList(widget.token);
    _clientsFuture = ClientService().getAllClients(widget.token);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
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
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _vaccinationsFuture,
          _animalsFuture,
          _clientsFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No vaccinations found for this veterinarian.'),
            );
          } else {
            final vaccinations = snapshot.data![0] as List<VaccinationModel>;
            final animals = snapshot.data![1] as List<AnimalModel>;
            final clients = snapshot.data![2] as List<ClientModel>;
            vaccinations.sort((a, b) => b.date.compareTo(a.date));
            final animalMap = {for (var animal in animals) animal.id: animal};
            final clientMapByUsername = {
              for (var client in clients) client.username: client,
            };
            final clientMapByEmail = {
              for (var client in clients) client.email: client,
            };
            final clientMapByPhone = {
              for (var client in clients) client.phoneNumber: client,
            };
            return ListView.builder(
              itemCount: vaccinations.length,
              itemBuilder: (context, index) {
                final vaccination = vaccinations[index];
                print('Vaccination Name: ${vaccination.name}');
                final animal = animalMap[vaccination.animalId];
                final animalName = animal?.name ?? 'Unknown';
                final ownerName =
                    vaccination.animal?.owner?.username ?? 'Unknown';
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vaccine: ${vaccination.name.isNotEmpty ? vaccination.name : "Unknown Vaccine"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'see_animal':
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final animal = vaccination.animal;
                                        return AlertDialog(
                                          title: const Text('Animal Details'),
                                          content:
                                              animal == null
                                                  ? const Text(
                                                    'No animal data available.',
                                                  )
                                                  : Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Name: ${animal.name}',
                                                      ),
                                                      Text(
                                                        'Species: ${animal.espece}',
                                                      ),
                                                      Text(
                                                        'Race: ${animal.race}',
                                                      ),
                                                      Text(
                                                        'Age: ${animal.age}',
                                                      ),
                                                      Text(
                                                        'Sex: ${animal.sexe}',
                                                      ),
                                                      Text(
                                                        'Allergies: ${animal.allergies}',
                                                      ),
                                                      Text(
                                                        'Medical History: ${animal.anttecedentsmedicaux}',
                                                      ),
                                                    ],
                                                  ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    break;
                                  case 'see_client':
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final client =
                                            vaccination.animal?.owner;
                                        return AlertDialog(
                                          title: const Text('Client Details'),
                                          content:
                                              client == null
                                                  ? const Text(
                                                    'No client data available.',
                                                  )
                                                  : Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Username: ${client.username}',
                                                      ),
                                                      Text(
                                                        'Email: ${client.email}',
                                                      ),
                                                      Text(
                                                        'Phone: ${client.phoneNumber}',
                                                      ),
                                                      Text(
                                                        'Address: ${client.address}',
                                                      ),
                                                    ],
                                                  ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    break;
                                  case 'see_details':
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Vaccination Details',
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Vaccine: ${vaccination.name}',
                                              ),
                                              Text(
                                                'Animal: ${vaccination.animal?.name ?? "Unknown"}',
                                              ),
                                              Text(
                                                'Owner: ${vaccination.animal?.owner?.username ?? "Unknown"}',
                                              ),
                                              Text(
                                                'Date: ${vaccination.date.toLocal().toString().split(' ')[0]}',
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    break;
                                  case 'update':
                                    final formKey = GlobalKey<FormState>();
                                    final TextEditingController
                                    vaccineNameController =
                                        TextEditingController(
                                          text: vaccination.name,
                                        );
                                    DateTime? selectedDate = vaccination.date;
                                    final TextEditingController dateController =
                                        TextEditingController(
                                          text:
                                              vaccination.date
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0],
                                        );

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return StatefulBuilder(
                                          builder: (context, setStateDialog) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Update Vaccination',
                                              ),
                                              content: Form(
                                                key: formKey,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextFormField(
                                                      controller:
                                                          vaccineNameController,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Vaccine Name',
                                                          ),
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please enter Vaccine Name';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    TextFormField(
                                                      controller:
                                                          dateController,
                                                      readOnly: true,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Date (YYYY-MM-DD)',
                                                            suffixIcon: Icon(
                                                              Icons
                                                                  .calendar_today,
                                                            ),
                                                          ),
                                                      onTap: () async {
                                                        DateTime? pickedDate =
                                                            await showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  selectedDate ??
                                                                  DateTime.now(),
                                                              firstDate:
                                                                  DateTime(
                                                                    2000,
                                                                  ),
                                                              lastDate:
                                                                  DateTime(
                                                                    2100,
                                                                  ),
                                                            );
                                                        if (pickedDate !=
                                                            null) {
                                                          setStateDialog(() {
                                                            selectedDate =
                                                                pickedDate;
                                                            dateController
                                                                    .text =
                                                                pickedDate
                                                                    .toLocal()
                                                                    .toString()
                                                                    .split(
                                                                      ' ',
                                                                    )[0];
                                                          });
                                                        }
                                                      },
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please enter Date';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    if (formKey.currentState!
                                                            .validate() &&
                                                        selectedDate != null) {
                                                      final dto = {
                                                        'AnimalId':
                                                            vaccination
                                                                .animalId,
                                                        'Name':
                                                            vaccineNameController
                                                                .text,
                                                        'Date':
                                                            selectedDate!
                                                                .toIso8601String(),
                                                      };
                                                      try {
                                                        await _service
                                                            .updateVaccination(
                                                              widget.token,
                                                              vaccination.id,
                                                              dto,
                                                            );
                                                        setState(() {
                                                          _vaccinationsFuture =
                                                              _service
                                                                  .getAllVaccinations(
                                                                    widget
                                                                        .token,
                                                                  );
                                                        });
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Vaccination updated successfully',
                                                            ),
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Failed to update vaccination: $e',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                    break;
                                  case 'delete':
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Confirm Delete'),
                                          content: const Text(
                                            'Are you sure you want to delete this vaccination?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                try {
                                                  await _service
                                                      .deleteVaccination(
                                                        widget.token,
                                                        vaccination.id,
                                                      );
                                                  setState(() {
                                                    _vaccinationsFuture =
                                                        _service
                                                            .getAllVaccinations(
                                                              widget.token,
                                                            );
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Vaccination deleted successfully',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to delete vaccination: \$e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
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
                                      value: 'see_details',
                                      child: Text('See Details'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'update',
                                      child: Text('Update'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Animal: $animalName'),
                        Text('Owner: $ownerName'),
                        Text(
                          'Date: ${vaccination.date.toLocal().toString().split(' ')[0]}',
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'returnBtn',
            onPressed: () {
              Navigator.pop(context); // Navigates back to the previous page
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Return'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addBtn',
            onPressed: () {
              _showAddVaccinationDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Vaccination'),
          ),
        ],
      ),
    );
  }

  void _showAddVaccinationDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController vaccineNameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Vaccination'),
          content: FutureBuilder<List<AnimalModel>>(
            future: _animalsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error loading animals: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No animals found.');
              } else {
                final animals = snapshot.data!;
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Animal',
                          ),
                          value: _selectedAnimalId,
                          items:
                              animals.map((animal) {
                                return DropdownMenuItem<String>(
                                  value: animal.id,
                                  child: Text(animal.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAnimalId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an animal';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: vaccineNameController,
                          decoration: const InputDecoration(
                            labelText: 'Vaccine Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Vaccine Name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Date (YYYY-MM-DD)',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                                _dateController.text =
                                    pickedDate.toLocal().toString().split(
                                      ' ',
                                    )[0];
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Date';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    _selectedAnimalId != null &&
                    _selectedDate != null) {
                  final dto = {
                    'animalId': _selectedAnimalId,
                    'Name': vaccineNameController.text,
                    'date': _selectedDate!.toIso8601String(),
                    'Notes': notesController.text,
                  };
                  try {
                    await _service.addVaccination(widget.token, dto);
                    setState(() {
                      _vaccinationsFuture = _service.getAllVaccinations(
                        widget.token,
                      );
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add vaccination: \$e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
