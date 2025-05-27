import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/vaccination_models/vaccination_model.dart';
import 'package:veterinary_app/services/vaccination_services/vaccination_service.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/services/client_services/client_service.dart'; // Keep this import, just in case ClientModel is used elsewhere
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
import 'package:veterinary_app/utils/app_colors.dart';

// --- DisplayVaccination Class (Keep this, crucial for organized data) ---
class DisplayVaccination {
  final VaccinationModel vaccination;
  final AnimalModel? animal;
  final ClientModel? owner; // This will now come directly from animal.owner

  DisplayVaccination({
    required this.vaccination,
    this.animal,
    this.owner,
  });

  String get vaccineName => vaccination.name.isNotEmpty ? vaccination.name : "Unknown Vaccine";
  String get animalName => animal?.name ?? 'Unknown'; // Using 'nom' from AnimalModel
  String get ownerName => owner?.username ?? 'Unknown'; // Using owner.username from ClientModel
  DateTime get date => vaccination.date;

  String get searchableContent {
    return '${vaccineName.toLowerCase()} '
        '${animalName.toLowerCase()} '
        '${ownerName.toLowerCase()} '
        '${vaccination.date.toLocal().toString().split(' ')[0].toLowerCase()}';
  }
}
// --- End DisplayVaccination Class ---

class VaccinationListPage extends StatefulWidget {
  final String token;
  final String username;

  const VaccinationListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<VaccinationListPage> createState() => _VaccinationListPageState();
}

class _VaccinationListPageState extends State<VaccinationListPage> {
  final VaccinationService _service = VaccinationService();
  final AnimalsVetService _animalService = AnimalsVetService();
  // Removed ClientService for getAllClients, as it's no longer needed for owner lookup here.
  // Kept ClientService import in case it's used elsewhere for other client operations.

  late Future<List<DisplayVaccination>> _processedVaccinationsFuture;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isAscendingSort = false;

  final TextEditingController _newVaccineNameController = TextEditingController();
  final TextEditingController _newDateController = TextEditingController();
  String? _newSelectedAnimalId;
  DateTime? _newSelectedDate;


  @override
  void initState() {
    super.initState();
    _processedVaccinationsFuture = _fetchAndProcessVaccinations();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _processedVaccinationsFuture = _fetchAndProcessVaccinations();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newVaccineNameController.dispose();
    _newDateController.dispose();
    super.dispose();
  }

  // --- Data Fetching and Processing ---
  Future<List<DisplayVaccination>> _fetchAndProcessVaccinations() async {
    try {
      final List<dynamic> results = await Future.wait([
        _service.getAllVaccinations(widget.token),
        _animalService.getAnimalsList(widget.token),
        // Removed _clientService.getAllClients(widget.token) as it's no longer necessary for owner lookup
      ]);

      final List<VaccinationModel> vaccinations = results[0] as List<VaccinationModel>;
      final List<AnimalModel> animals = results[1] as List<AnimalModel>;
      // final List<ClientModel> clients = results[2] as List<ClientModel>; // No longer needed

      print('--- Data Fetch Status ---');
      print('Vaccinations fetched: ${vaccinations.length}');
      print('Animals fetched: ${animals.length}');
      // print('Clients fetched: ${clients.length}'); // No longer needed

      final Map<String, AnimalModel> animalMap = {for (var a in animals) a.id: a};

      // Removed clientMapById and clientMapByUsername as direct owner object is available

      List<DisplayVaccination> displayList = vaccinations.map((vaccination) {
        final AnimalModel? animal = animalMap[vaccination.animalId];

        ClientModel? owner;
        if (animal != null) {
          // *** Direct Assignment: Use the nested owner object if present ***
          owner = animal.owner; // Direct assignment from AnimalModel's parsed owner

          print('--- Processing Vaccination ---');
          print('Vaccination ID: ${vaccination.id}');
          print('Animal ID from Vaccination: ${vaccination.animalId}');
          print('Animal Name: ${animal.name}'); // Using 'nom' from AnimalModel
          print('Animal\'s ownerId field: ${animal.ownerId}'); // Still useful for debug/info
          print('Resolved Owner Username: ${owner?.username ?? 'NOT FOUND (Nested owner was null)'}');

        } else {
          print('--- Processing Vaccination ---');
          print('Vaccination ID: ${vaccination.id}');
          print('Animal not found for Vaccination Animal ID: ${vaccination.animalId}');
        }

        return DisplayVaccination(
          vaccination: vaccination,
          animal: animal,
          owner: owner, // This will now be the directly found owner
        );
      }).toList();

      // 1. Filter based on search query
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        displayList = displayList.where((displayItem) {
          return displayItem.searchableContent.contains(queryLower);
        }).toList();
      }

      // 2. Sort the list based on _isAscendingSort (old to new or new to old)
      if (_isAscendingSort) {
        displayList.sort((a, b) => a.date.compareTo(b.date));
      } else {
        displayList.sort((a, b) => b.date.compareTo(a.date));
      }

      return displayList;
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  // ... (rest of your methods remain the same) ...
  // Ensure that in DisplayVaccination, animalName uses animal.nom, not animal.name
  // And ownerName uses owner.username, which it already does.

  // --- Helper for showing snackbar messages ---
  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // --- Helper for formatting date ---
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  // --- Common Dialog Detail Row Widget ---
  Widget _buildDialogDetailRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label",
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---
  void _showAnimalDetailsDialog(AnimalModel? animal) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.pets, color: kPrimaryGreen),
              const SizedBox(width: 10),
              Text(
                'Animal Details: ${animal?.name ?? 'Unknown'}', // Changed to animal?.nom
                style: textTheme.titleLarge?.copyWith(color: kPrimaryGreen),
              ),
            ],
          ),
          content: animal == null
              ? Text('No animal data available.', style: textTheme.bodyLarge)
              : SingleChildScrollView(
            child: ListBody(
              children: [
                _buildDialogDetailRow(textTheme, 'Species:', animal.espece),
                _buildDialogDetailRow(textTheme, 'Breed:', animal.race),
                _buildDialogDetailRow(textTheme, 'Age:', animal.age.toString()),
                _buildDialogDetailRow(textTheme, 'Sex:', animal.sexe),
                _buildDialogDetailRow(textTheme, 'Allergies:', animal.allergies.isNotEmpty ? animal.allergies : 'None'),
                _buildDialogDetailRow(textTheme, 'Medical History:', animal.anttecedentsmedicaux.isNotEmpty ? animal.anttecedentsmedicaux : 'None'),
                _buildDialogDetailRow(textTheme, 'Owner:', animal.owner?.username ?? 'N/A'), // Display owner from nested object
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.grey[700])),
            ),
          ],
        );
      },
    );
  }

  void _showClientDetailsDialog(ClientModel? client) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.person, color: kPrimaryGreen),
              const SizedBox(width: 10),
              Text(
                'Client Details: ${client?.username ?? 'Unknown'}',
                style: textTheme.titleLarge?.copyWith(color: kPrimaryGreen),
              ),
            ],
          ),
          content: client == null
              ? Text('No client data available.', style: textTheme.bodyLarge)
              : SingleChildScrollView(
            child: ListBody(
              children: [
                _buildDialogDetailRow(textTheme, 'Username:', client.username),
                _buildDialogDetailRow(textTheme, 'Email:', client.email),
                _buildDialogDetailRow(textTheme, 'Phone:', client.phoneNumber),
                _buildDialogDetailRow(textTheme, 'Address:', client.address),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.grey[700])),
            ),
          ],
        );
      },
    );
  }

  void _showVaccinationDetailsDialog(DisplayVaccination displayVaccination) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.vaccines, color: kPrimaryGreen),
              const SizedBox(width: 10),
              Text(
                'Vaccination Details',
                style: textTheme.titleLarge?.copyWith(color: kPrimaryGreen),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _buildDialogDetailRow(textTheme, 'Vaccine:', displayVaccination.vaccineName),
                _buildDialogDetailRow(textTheme, 'Animal:', displayVaccination.animalName),
                _buildDialogDetailRow(textTheme, 'Owner:', displayVaccination.ownerName),
                _buildDialogDetailRow(textTheme, 'Date:', _formatDate(displayVaccination.date)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.grey[700])),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateVaccinationDialog(DisplayVaccination displayVaccination) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController vaccineNameController = TextEditingController(text: displayVaccination.vaccineName);
    DateTime? selectedDate = displayVaccination.date;
    final TextEditingController dateController = TextEditingController(text: _formatDate(displayVaccination.date).split(' ')[0]);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              backgroundColor: Theme.of(context).cardColor,
              title: Row(
                children: [
                  Icon(Icons.edit, color: kAccentGreen),
                  const SizedBox(width: 10),
                  Text('Update Vaccination', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kAccentGreen)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: vaccineNameController,
                      decoration: InputDecoration(
                        labelText: 'Vaccine Name',
                        labelStyle: TextStyle(color: kPrimaryGreen),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter Vaccine Name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: kPrimaryGreen),
                        suffixIcon: Icon(Icons.calendar_today, color: kPrimaryGreen),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: kPrimaryGreen,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: kPrimaryGreen,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDate = pickedDate;
                            dateController.text = pickedDate.toLocal().toString().split(' ')[0];
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() && selectedDate != null) {
                      final dto = {
                        'AnimalId': displayVaccination.vaccination.animalId,
                        'Name': vaccineNameController.text,
                        'Date': selectedDate!.toIso8601String(),
                      };
                      try {
                        await _service.updateVaccination(
                          widget.token,
                          displayVaccination.vaccination.id,
                          dto,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        _showSnackBar('Vaccination updated successfully');
                        setState(() {
                          _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                        });
                      } catch (e) {
                        _showSnackBar('Failed to update vaccination: $e', isSuccess: false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteVaccinationDialog(String vaccinationId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              const SizedBox(width: 10),
              Text('Confirm Delete', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red)),
            ],
          ),
          content: const Text('Are you sure you want to delete this vaccination? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (context.mounted) Navigator.of(context).pop();
                try {
                  await _service.deleteVaccination(widget.token, vaccinationId);
                  _showSnackBar('Vaccination deleted successfully');
                  setState(() {
                    _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                  });
                } catch (e) {
                  _showSnackBar('Failed to delete vaccination: $e', isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // --- Add Vaccination Dialog ---
  void _showAddVaccinationDialog() {
    final addFormKey = GlobalKey<FormState>();
    _newVaccineNameController.clear();
    _newDateController.clear();
    _newSelectedAnimalId = null;
    _newSelectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              backgroundColor: Theme.of(context).cardColor,
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: kPrimaryGreen),
                  const SizedBox(width: 10),
                  Text('Add New Vaccination', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kPrimaryGreen)),
                ],
              ),
              content: Form(
                key: addFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _newVaccineNameController,
                        decoration: InputDecoration(
                          labelText: 'Vaccine Name',
                          labelStyle: TextStyle(color: kPrimaryGreen),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Vaccine Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<AnimalModel>>(
                        future: _animalService.getAnimalsList(widget.token),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error loading animals: ${snapshot.error}');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No animals available. Please add an animal first.');
                          } else {
                            final animals = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Animal',
                                labelStyle: TextStyle(color: kPrimaryGreen),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                                border: OutlineInputBorder(),
                              ),
                              value: _newSelectedAnimalId,
                              hint: const Text('Choose an animal'),
                              onChanged: (String? newValue) {
                                setStateDialog(() {
                                  _newSelectedAnimalId = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select an animal';
                                }
                                return null;
                              },
                              items: animals.map<DropdownMenuItem<String>>((AnimalModel animal) {
                                return DropdownMenuItem<String>(
                                  value: animal.id,
                                  child: Text(animal.name), // Use animal.nom for display
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date (YYYY-MM-DD)',
                          labelStyle: TextStyle(color: kPrimaryGreen),
                          suffixIcon: Icon(Icons.calendar_today, color: kPrimaryGreen),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _newSelectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: kPrimaryGreen,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: kPrimaryGreen,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              _newSelectedDate = pickedDate;
                              _newDateController.text = pickedDate.toLocal().toString().split(' ')[0];
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (addFormKey.currentState!.validate() && _newSelectedAnimalId != null && _newSelectedDate != null) {
                      final dto = {
                        'AnimalId': _newSelectedAnimalId,
                        'Name': _newVaccineNameController.text,
                        'Date': _newSelectedDate!.toIso8601String(),
                      };
                      try {
                        await _service.addVaccination(widget.token, dto);
                        if (context.mounted) Navigator.of(context).pop();
                        _showSnackBar('Vaccination added successfully');
                        setState(() {
                          _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                        });
                      } catch (e) {
                        _showSnackBar('Failed to add vaccination: $e', isSuccess: false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vaccinations (vaccine, animal, owner, date)',
                      prefixIcon: Icon(Icons.search, color: kPrimaryGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _isAscendingSort ? Icons.arrow_upward : Icons.arrow_downward,
                    color: kPrimaryGreen,
                    size: 28,
                  ),
                  tooltip: _isAscendingSort ? 'Sort by Date (Oldest First)' : 'Sort by Date (Newest First)',
                  onPressed: () {
                    setState(() {
                      _isAscendingSort = !_isAscendingSort;
                      _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DisplayVaccination>>(
              future: _processedVaccinationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vaccines_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching vaccinations found.'
                              : 'No vaccinations found. Add a new one!',
                          style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  final vaccinations = snapshot.data!;
                  return ListView.builder(
                    itemCount: vaccinations.length,
                    itemBuilder: (context, index) {
                      final displayVaccination = vaccinations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: InkWell(
                          onTap: () => _showVaccinationDetailsDialog(displayVaccination),
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Vaccine: ${displayVaccination.vaccineName}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryGreen,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _formatDate(displayVaccination.date),
                                      style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const Divider(height: 15, thickness: 1),
                                Text(
                                  'Animal: ${displayVaccination.animalName}',
                                  style: textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Owner: ${displayVaccination.ownerName}',
                                  style: textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.pets_outlined, size: 20),
                                      label: const Text('Animal'),
                                      onPressed: () => _showAnimalDetailsDialog(displayVaccination.animal),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.teal,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton.icon(
                                      icon: const Icon(Icons.person_outline, size: 20),
                                      label: const Text('Owner'),
                                      onPressed: () => _showClientDetailsDialog(displayVaccination.owner),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.deepPurple,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        switch (value) {
                                          case 'see_animal':
                                            _showAnimalDetailsDialog(displayVaccination.animal);
                                            break;
                                          case 'see_client':
                                            _showClientDetailsDialog(displayVaccination.owner);
                                            break;
                                          case 'see_details':
                                            _showVaccinationDetailsDialog(displayVaccination);
                                            break;
                                          case 'update':
                                            await _showUpdateVaccinationDialog(displayVaccination);
                                            break;
                                          case 'delete':
                                            await _showDeleteVaccinationDialog(displayVaccination.vaccination.id);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
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
                                      offset: const Offset(0, 40),
                                      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addBtn',
            onPressed: () {
              _showAddVaccinationDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Vaccination'),
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          const SizedBox(height: 12),

        ],
      ),
    );
  }
}