import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/vaccination_models/vaccination_model.dart';
import 'package:veterinary_app/services/vaccination_services/vaccination_service.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
import 'package:veterinary_app/utils/app_colors.dart';

// --- DisplayVaccination Class (Keep this, crucial for organized data) ---
class DisplayVaccination {
  final VaccinationModel vaccination;
  final AnimalModel? animal;
  final ClientModel? owner;

  DisplayVaccination({
    required this.vaccination,
    this.animal,
    this.owner,
  });

  String get vaccineName => vaccination.name.isNotEmpty ? vaccination.name : "Unknown Vaccine";
  String get animalName => animal?.name ?? 'Unknown';
  String get ownerName => owner?.username ?? 'Unknown';
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

  late Future<List<DisplayVaccination>> _processedVaccinationsFuture;
  // This _dateController and _selectedDateTime are for the *page* itself,
  // potentially if you had a date filter on the main page.
  // For the ADD dialog, we'll use local variables within the dialog's StatefulBuilder.
  final TextEditingController _dateController = TextEditingController(); // For the main page's date field, if any
  DateTime? _selectedDateTime; // For the main page's date field, if any


  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isAscendingSort = false;

  // These controllers are for the ADD vaccination dialog
  final TextEditingController _newVaccineNameController = TextEditingController();
  // Removed _newDateController here as it will be managed locally in the dialog
  // Removed _newSelectedDate here as it will be managed locally in the dialog
  String? _newSelectedAnimalId; // This one is fine to keep as a state variable if you manage dropdown state centrally


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
    _dateController.dispose(); // Dispose the main page's date controller
    // No need to dispose _newDateController if it's local to the dialog
    super.dispose();
  }

  Future<List<DisplayVaccination>> _fetchAndProcessVaccinations() async {
    try {
      final List<dynamic> results = await Future.wait([
        _service.getAllVaccinations(widget.token),
        _animalService.getAnimalsList(widget.token),
      ]);

      final List<VaccinationModel> vaccinations = results[0] as List<VaccinationModel>;
      final List<AnimalModel> animals = results[1] as List<AnimalModel>;

      print('--- Data Fetch Status ---');
      print('Vaccinations fetched: ${vaccinations.length}');
      print('Animals fetched: ${animals.length}');

      final Map<String, AnimalModel> animalMap = {for (var a in animals) a.id: a};

      List<DisplayVaccination> displayList = vaccinations.map((vaccination) {
        final AnimalModel? animal = animalMap[vaccination.animalId];

        ClientModel? owner;
        if (animal != null) {
          owner = animal.owner;

          print('--- Processing Vaccination ---');
          print('Vaccination ID: ${vaccination.id}');
          print('Animal ID from Vaccination: ${vaccination.animalId}');
          print('Animal Name: ${animal.name}');
          print('Animal\'s ownerId field: ${animal.ownerId}');
          print('Resolved Owner Username: ${owner?.username ?? 'NOT FOUND (Nested owner was null)'}');

        } else {
          print('--- Processing Vaccination ---');
          print('Vaccination ID: ${vaccination.id}');
          print('Animal not found for Vaccination Animal ID: ${vaccination.animalId}');
        }

        return DisplayVaccination(
          vaccination: vaccination,
          animal: animal,
          owner: owner,
        );
      }).toList();

      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        displayList = displayList.where((displayItem) {
          return displayItem.searchableContent.contains(queryLower);
        }).toList();
      }

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

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

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
                'Animal Details: ${animal?.name ?? 'Unknown'}',
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
                _buildDialogDetailRow(textTheme, 'Owner:', animal.owner?.username ?? 'N/A'),
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

  // This _selectDateTime is for the main page's date field, if you had one.
  // It uses _selectedDateTime and _dateController which are state variables of VaccinationListPage.
  // We need a *different* version for the Add/Update dialogs.
  /*
  Future<void> _selectDateTime() async {
    DateTime initialDate = _selectedDateTime ?? DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimaryGreen,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
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

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = selectedDateTime;
          _dateController.text = DateFormat('dd MMM yyyy HH:mm').format(selectedDateTime);
        });
      }
    }
  }
  */

  Future<void> _showUpdateVaccinationDialog(DisplayVaccination displayVaccination) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController vaccineNameController = TextEditingController(text: displayVaccination.vaccineName);
    // Use a local variable for the selected date in the dialog
    DateTime? dialogSelectedDate = displayVaccination.date;
    final TextEditingController dateController = TextEditingController(text: _formatDate(displayVaccination.date)); // Initialize with full date and time

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Local function for date/time picking within this dialog's scope
            Future<void> selectDateTimeForDialog() async {
              DateTime initialDialogDate = dialogSelectedDate ?? DateTime.now();

              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDialogDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: kPrimaryGreen,
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
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
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDialogDate),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: kPrimaryGreen,
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
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

                if (pickedTime != null) {
                  final selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  setStateDialog(() { // Use setStateDialog to update dialog's state
                    dialogSelectedDate = selectedDateTime;
                    dateController.text = DateFormat('dd MMM yyyy HH:mm').format(selectedDateTime);
                  });
                }
              }
            }

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
                      controller: dateController, // Use the local dateController
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date and Time (YYYY-MM-DD HH:MM)', // Updated label
                        labelStyle: TextStyle(color: kPrimaryGreen),
                        suffixIcon: Icon(Icons.calendar_today, color: kPrimaryGreen),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryGreen, width: 2)),
                      ),
                      onTap: selectDateTimeForDialog, // Call the local dialog function
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select Date and Time';
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
                    // Check form validation and that the dialogSelectedDate is not null
                    if (formKey.currentState!.validate() && dialogSelectedDate != null) {
                      final dto = {
                        'AnimalId': displayVaccination.vaccination.animalId,
                        'Name': vaccineNameController.text,
                        'Date': dialogSelectedDate!.toIso8601String(), // Use dialogSelectedDate here
                      };
                      try {
                        await _service.updateVaccination(
                          widget.token,
                          displayVaccination.vaccination.id,
                          dto,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        _showSnackBar('Vaccination updated successfully');
                        setState(() { // This setState is for the main page to refresh its list
                          _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                        });
                      } catch (e) {
                        _showSnackBar('Failed to update vaccination: $e', isSuccess: false);
                      }
                    } else {
                      _showSnackBar('Please ensure all fields are filled and valid.', isSuccess: false);
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
    _newSelectedAnimalId = null;
    // These will be managed locally within the dialog's StatefulBuilder
    TextEditingController addDialogDateController = TextEditingController();
    DateTime? addDialogSelectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Local function for date/time picking within this dialog's scope
            Future<void> selectDateTimeForAddDialog() async {
              DateTime initialAddDialogDate = addDialogSelectedDate ?? DateTime.now();

              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialAddDialogDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: kPrimaryGreen,
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
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
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialAddDialogDate),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: kPrimaryGreen,
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
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

                if (pickedTime != null) {
                  final selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  setStateDialog(() { // Use setStateDialog to update dialog's state
                    addDialogSelectedDate = selectedDateTime;
                    addDialogDateController.text = DateFormat('dd MMM yyyy HH:mm').format(selectedDateTime);
                  });
                }
              }
            }

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
                                  child: Text(animal.name),
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addDialogDateController, // Use the local dialog controller
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Select Date and Time',
                          labelStyle: TextStyle(color: kPrimaryGreen),
                          prefixIcon: Icon(Icons.calendar_today_rounded, color: kPrimaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onTap: selectDateTimeForAddDialog, // Call the local dialog function
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select Date and Time';
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
                    // Critical: Check addDialogSelectedDate instead of _newSelectedDate
                    if (addFormKey.currentState!.validate() && _newSelectedAnimalId != null && addDialogSelectedDate != null) {
                      final dto = {
                        'AnimalId': _newSelectedAnimalId,
                        'Name': _newVaccineNameController.text,
                        'Date': addDialogSelectedDate!.toIso8601String(), // Use addDialogSelectedDate
                      };
                      try {
                        await _service.addVaccination(widget.token, dto);
                        if (context.mounted) Navigator.of(context).pop();
                        _showSnackBar('Vaccination added successfully');
                        setState(() { // This setState is for the main page to refresh its list
                          _processedVaccinationsFuture = _fetchAndProcessVaccinations();
                        });
                      } catch (e) {
                        _showSnackBar('Failed to add vaccination: $e', isSuccess: false);
                      }
                    } else {
                      _showSnackBar('Please ensure all fields are filled and valid.', isSuccess: false);
                      print('Add Dialog Validation Failed:');
                      print('Form Valid: ${addFormKey.currentState!.validate()}');
                      print('Animal Selected: $_newSelectedAnimalId');
                      print('Date Selected: $addDialogSelectedDate');
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
                      prefixIcon: Icon(Icons.search, color: kPrimaryGreen), // Assuming kPrimaryGreen for search icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(_isAscendingSort ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _isAscendingSort = !_isAscendingSort;
                      _processedVaccinationsFuture = _fetchAndProcessVaccinations(); // Re-fetch to apply sort
                    });
                  },
                  tooltip: _isAscendingSort ? 'Sort by date (newest first)' : 'Sort by date (oldest first)',
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vaccines_rounded, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text('No vaccinations found.', style: textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _showAddVaccinationDialog,
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                          label: Text('Add New Vaccination', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final filteredVaccinations = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: filteredVaccinations.length,
                    itemBuilder: (context, index) {
                      final displayVaccination = filteredVaccinations[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayVaccination.vaccineName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryGreen,
                                ),
                              ),
                              const Divider(height: 20, thickness: 1),
                              Row(
                                children: [
                                  Icon(Icons.pets, color: kAccentGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Animal: ${displayVaccination.animalName}',
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline, color: kAccentGreen),
                                    onPressed: () => _showAnimalDetailsDialog(displayVaccination.animal),
                                    tooltip: 'View Animal Details',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, color: kAccentGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Owner: ${displayVaccination.ownerName}',
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline, color: kAccentGreen),
                                    onPressed: () => _showClientDetailsDialog(displayVaccination.owner),
                                    tooltip: 'View Owner Details',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: kAccentGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Date: ${_formatDate(displayVaccination.date)}',
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info_outline, color: kPrimaryGreen),
                                    onPressed: () => _showVaccinationDetailsDialog(displayVaccination),
                                    tooltip: 'More Details',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: kAccentGreen),
                                    onPressed: () => _showUpdateVaccinationDialog(displayVaccination),
                                    tooltip: 'Edit Vaccination',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_forever, color: Colors.red),
                                    onPressed: () => _showDeleteVaccinationDialog(displayVaccination.vaccination.id),
                                    tooltip: 'Delete Vaccination',
                                  ),
                                ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVaccinationDialog,
        label: Text('Add New Vaccination', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}