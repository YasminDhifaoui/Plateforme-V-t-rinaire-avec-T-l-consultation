import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/vaccination_models/vaccination_model.dart';
import '../../services/vaccination_services/vaccination_service.dart';
import '../components/home_navbar.dart';
import 'package:veterinary_app/utils/app_colors.dart';

// Enum to define sorting options
enum _SortOrder {
  nameAsc,  // Vaccine Name A-Z
  nameDesc, // Vaccine Name Z-A
  dateDesc, // Date Newest First
  dateAsc,  // Date Oldest First
}

class VaccinationByAnimalPage extends StatefulWidget {
  final String token;
  final String animalId;
  final String animalName;

  const VaccinationByAnimalPage({
    Key? key,
    required this.token,
    required this.animalId,
    required this.animalName,
  }) : super(key: key);

  @override
  _VaccinationByAnimalPageState createState() => _VaccinationByAnimalPageState();
}

class _VaccinationByAnimalPageState extends State<VaccinationByAnimalPage> {
  late Future<List<VaccinationModel>> _vaccinationFuture;
  final VaccinationService _service = VaccinationService();

  // Controllers for the new vaccination dialog
  final TextEditingController _newVaccineNameController = TextEditingController();
  final TextEditingController _newDateController = TextEditingController();
  DateTime? _newSelectedDate;

  // For Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<VaccinationModel> _allVaccinations = [];
  List<VaccinationModel> _filteredVaccinations = [];

  // For Sorting functionality
  _SortOrder _currentSortOrder = _SortOrder.dateDesc; // Default sort: Newest Date First


  @override
  void initState() {
    super.initState();
    _fetchVaccinations();
    _searchController.addListener(_filterVaccinations);
  }

  @override
  void dispose() {
    _newVaccineNameController.dispose();
    _newDateController.dispose();
    _searchController.removeListener(_filterVaccinations);
    _searchController.dispose();
    super.dispose();
  }

  void _fetchVaccinations() {
    if (widget.animalId.isNotEmpty) {
      _vaccinationFuture =
          _service.getVaccinationsByAnimalId(widget.token, widget.animalId)
              .then((vaccinations) {
            _allVaccinations = vaccinations;
            _sortAndFilterVaccinations(); // Sort and filter after fetching
            return vaccinations;
          }).catchError((error) {
            _allVaccinations = [];
            _filteredVaccinations = [];
            throw error;
          });
    } else {
      _vaccinationFuture = Future.error('Invalid animal ID provided.');
    }
  }

  // New method to sort the list
  void _sortVaccinations(List<VaccinationModel> list) {
    list.sort((a, b) {
      switch (_currentSortOrder) {
        case _SortOrder.nameAsc:
          return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
        case _SortOrder.nameDesc:
          return (b.name ?? '').toLowerCase().compareTo((a.name ?? '').toLowerCase());
        case _SortOrder.dateAsc:
          DateTime dateA = DateTime.tryParse(a.date.toString()) ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b.date.toString()) ?? DateTime(1970);
          return dateA.compareTo(dateB);
        case _SortOrder.dateDesc:
          DateTime dateA = DateTime.tryParse(a.date.toString()) ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b.date.toString()) ?? DateTime(1970);
          return dateB.compareTo(dateA);
        default:
          return 0; // No specific sort
      }
    });
  }

  // Method to filter vaccinations based on search query AND apply current sort order
  void _sortAndFilterVaccinations() {
    // First, sort the entire list
    _sortVaccinations(_allVaccinations);

    // Then, apply the filter
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVaccinations = _allVaccinations.where((vaccine) {
        return (vaccine.name ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  void _filterVaccinations() {
    _sortAndFilterVaccinations();
  }

  void _refreshVaccinationList() {
    setState(() {
      _fetchVaccinations();
    });
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'N/A';

    DateTime? parsedDate;

    if (dateData is String) {
      try {
        parsedDate = DateTime.parse(dateData);
      } catch (e) {
        debugPrint('Error parsing date string "$dateData": $e');
        return 'Invalid Date String';
      }
    } else if (dateData is DateTime) {
      parsedDate = dateData;
    } else {
      debugPrint('Unexpected date type: ${dateData.runtimeType}');
      return 'Unexpected Date Type';
    }

    if (parsedDate != null) {
      return DateFormat('dd MMMEEEE HH:mm').format(parsedDate);
    } else {
      return 'N/A';
    }
  }

  Future<void> _showAddVaccinationDialogForAnimal() async {
    final addFormKey = GlobalKey<FormState>();
    _newVaccineNameController.clear();
    _newDateController.clear();
    _newSelectedDate = null;

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
                  Icon(Icons.add_circle, color: kPrimaryGreen),
                  const SizedBox(width: 10),
                  Text(
                    'Add Vaccination for ${widget.animalName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kPrimaryGreen),
                  ),
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
                      TextFormField(
                        controller: _newDateController,
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
                        onTap: () async {
                          DateTime initialDate = _newSelectedDate ?? DateTime.now();
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

                              setStateDialog(() {
                                _newSelectedDate = selectedDateTime;
                                _newDateController.text = DateFormat('dd MMMEEEE HH:mm').format(selectedDateTime);
                              });
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date and time';
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
                    if (addFormKey.currentState!.validate() && _newSelectedDate != null) {
                      final dto = {
                        'AnimalId': widget.animalId,
                        'Name': _newVaccineNameController.text,
                        'Date': _newSelectedDate!.toIso8601String(),
                      };
                      try {
                        await _service.addVaccination(widget.token, dto);
                        if (context.mounted) Navigator.of(context).pop();
                        _showSnackBar('Vaccination added successfully');
                        _refreshVaccinationList();
                      } catch (e) {
                        _showSnackBar('Failed to add vaccination: $e', isSuccess: false);
                      }
                    } else {
                      _showSnackBar('Please fill all fields and select a date/time.', isSuccess: false);
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: HomeNavbar(
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        // Removed 'actions' parameter from HomeNavbar
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                label: Text('Return', style: textTheme.labelLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vaccinations by name...',
                prefixIcon: Icon(Icons.search, color: kPrimaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    _filterVaccinations(); // Re-trigger filter
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: textTheme.bodyMedium,
            ),
          ),
          // Sort Button below the search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight, // Align the button to the right
              child: PopupMenuButton<_SortOrder>(
                icon: Icon(Icons.sort, color: kPrimaryGreen), // Icon for the sort button
                tooltip: 'Sort Vaccinations',
                onSelected: (order) {
                  setState(() {
                    _currentSortOrder = order;
                    _sortAndFilterVaccinations(); // Re-sort and re-filter
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<_SortOrder>>[
                  PopupMenuItem<_SortOrder>(
                    value: _SortOrder.nameAsc,
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, color: kPrimaryGreen),
                        SizedBox(width: 8),
                        Text('Name (A-Z)', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem<_SortOrder>(
                    value: _SortOrder.nameDesc,
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, color: kPrimaryGreen),
                        SizedBox(width: 8),
                        Text('Name (Z-A)', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_SortOrder>(
                    value: _SortOrder.dateDesc,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: kPrimaryGreen),
                        SizedBox(width: 8),
                        Text('Date (Newest First)', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem<_SortOrder>(
                    value: _SortOrder.dateAsc,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: kPrimaryGreen),
                        SizedBox(width: 8),
                        Text('Date (Oldest First)', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<VaccinationModel>>(
              future: _vaccinationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryGreen));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade400,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load vaccinations: ${snapshot.error}',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshVaccinationList,
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            label: Text('Retry', style: textTheme.labelLarge),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final vaccinationsToDisplay = _filteredVaccinations;

                if (vaccinationsToDisplay.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vaccines_rounded,
                          color: kAccentGreen,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No vaccinations found matching "${_searchController.text}".'
                              : 'No vaccinations found for this animal.',
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (_searchController.text.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              _filterVaccinations();
                            },
                            icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                            label: Text('Clear Search', style: textTheme.labelLarge),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentGreen,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          Text(
                            'Add new vaccination records to see them here.',
                            style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: vaccinationsToDisplay.length,
                  itemBuilder: (context, index) {
                    final vaccine = vaccinationsToDisplay[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.vaccines_rounded, color: kPrimaryGreen, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vaccine.name ?? 'Unknown Vaccine',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 0.8, color: Colors.grey),
                              _buildVaccinationInfoRow(textTheme, Icons.calendar_today_rounded, 'Date', _formatDate(vaccine.date)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVaccinationDialogForAnimal,
        label: Text('Add Vaccination', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildVaccinationInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccentGreen),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}