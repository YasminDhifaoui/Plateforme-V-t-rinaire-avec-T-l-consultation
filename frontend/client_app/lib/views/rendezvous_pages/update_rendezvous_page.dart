import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_app/models/rendezvous_models/rendezvous.dart';
import 'package:client_app/services/rendezvous_services/update_rendezvous.dart';
// import 'package:client_app/views/components/home_navbar.dart'; // Replaced with standard AppBar
// import 'package:client_app/utils/logout_helper.dart'; // Keep if needed for general logout logic
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/services/vet_services/veterinaire_service.dart';
import 'package:client_app/models/vet_models/veterinaire.dart';
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

class UpdateRendezvousPage extends StatefulWidget {
  const UpdateRendezvousPage({Key? key}) : super(key: key);

  @override
  State<UpdateRendezvousPage> createState() => _UpdateRendezvousPageState();
}

class _UpdateRendezvousPageState extends State<UpdateRendezvousPage> {
  late Rendezvous rendezvous;

  final TextEditingController _dateController = TextEditingController();

  List<Animal> _animals = [];
  List<Veterinaire> _veterinaires = [];
  Animal? _selectedAnimal;
  Veterinaire? _selectedVeterinaire;
  bool _isLoading = true;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // No initialization here, it's handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      rendezvous = args['rendezvous'] as Rendezvous;
      final passedVetName = args['vetName'] as String?;
      _dateController.text =
          DateFormat('dd-MM-yyyy HH:mm').format(rendezvous.date);
      _loadData(passedVetName);
      _isInitialized = true;
    }
  }

  Future<void> _loadData([String? passedVetName]) async {
    try {
      final animals = await AnimalService().getAnimalsList();
      final vets = await VeterinaireService().getAllVeterinaires();

      setState(() {
        _animals = animals;
        _veterinaires = vets;
        _isLoading = false;

        _selectedAnimal = animals.firstWhere(
              (a) =>
          a.name.toLowerCase().trim() ==
              rendezvous.animalName.toLowerCase().trim(),
          orElse: () {
            print('Animal not found: ${rendezvous.animalName}');
            return animals.first;
          },
        );

        _selectedVeterinaire = vets.firstWhere(
              (v) => v.username == (passedVetName ?? rendezvous.vetName),
          orElse: () {
            print('Veterinarian not found: ${passedVetName ?? rendezvous.vetName}');
            return vets.first; // Fallback to first vet if not found
          },
        );
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data: $e', isSuccess: false);
    }
  }

  Future<void> _selectDateTime() async {
    DateTime initialDate = rendezvous.date.isBefore(DateTime.now())
        ? DateTime.now()
        : rendezvous.date;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black87, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryBlue, // Button text color
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
        initialTime: TimeOfDay.fromDateTime(rendezvous.date),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimaryBlue, // Header background color
                onPrimary: Colors.white, // Header text color
                onSurface: Colors.black87, // Body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryBlue, // Button text color
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
          rendezvous = Rendezvous(
            id: rendezvous.id,
            animalName: rendezvous.animalName,
            vetName: rendezvous.vetName,
            date: selectedDateTime,
            status: rendezvous.status,
          );
          _dateController.text =
              DateFormat('dd-MM-yyyy HH:mm').format(selectedDateTime);
        });
      }
    }
  }

  void _updateRendezvous() async {
    setState(() => _isLoading = true); // Set loading true during update
    final vetIdToSend = _selectedVeterinaire?.id;
    if (vetIdToSend == null) {
      _showSnackBar('Error: Veterinarian not found.', isSuccess: false);
      setState(() => _isLoading = false);
      return;
    }

    final data = {
      "animalId": _selectedAnimal?.id, // ✅ Send the animal's ID here
      "vetId": vetIdToSend,
      "date": DateFormat('yyyy-MM-ddTHH:mm:ss')
          .format(DateFormat('dd-MM-yyyy HH:mm').parse(_dateController.text)),
      "status": rendezvous.status.name,
    };

    print('Sending data: $data'); // For debugging

    try {
      await UpdateRendezvousService().updateRendezvous(rendezvous.id, data);
      _showSnackBar('Appointment updated successfully!', isSuccess: true);
      Navigator.pop(context, true); // <- send 'true' to indicate successful update
    } catch (e) {
      _showSnackBar('Failed to update appointment: $e', isSuccess: false);
    } finally {
      setState(() => _isLoading = false); // Set loading false after update attempt
    }
  }

  // Helper to show themed SnackBar feedback
  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Reusable text field builder with themed icons & style
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      TextTheme textTheme, {
        bool isOptional = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // Increased spacing
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: isOptional ? '(Optional)' : null,
          prefixIcon: Icon(icon, color: kAccentBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
          ),
          labelStyle: TextStyle(color: kPrimaryBlue),
          floatingLabelStyle: TextStyle(color: kPrimaryBlue, fontSize: 18),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: isOptional
            ? null
            : validator ??
                (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Update Appointment', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryBlue)) // Themed loading indicator
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Edit Appointment Details",
              style: textTheme.headlineSmall?.copyWith(
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // 🔹 Animal Dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Select Animal',
                labelStyle: TextStyle(color: kPrimaryBlue),
                prefixIcon: Icon(Icons.pets_rounded, color: kAccentBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Animal>(
                  isExpanded: true,
                  value: _selectedAnimal,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryBlue),
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  items: _animals.map((animal) {
                    return DropdownMenuItem(
                      value: animal,
                      child: Text(animal.name),
                    );
                  }).toList(),
                  onChanged: (animal) {
                    setState(() {
                      _selectedAnimal = animal;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Veterinarian Field (Read-only)
            _buildTextField(
              TextEditingController(
                text: _selectedVeterinaire != null
                    ? (_selectedVeterinaire!.firstName.isNotEmpty &&
                    _selectedVeterinaire!.lastName.isNotEmpty
                    ? '${_selectedVeterinaire!.firstName} ${_selectedVeterinaire!.lastName}'
                    : _selectedVeterinaire!.username)
                    : rendezvous.vetName,
              ),
              'Veterinarian',
              Icons.medical_services_rounded,
              textTheme,
              readOnly: true, // This field is read-only
            ),

            // 🔹 Date and Time Picker
            _buildTextField(
              _dateController,
              'Date and Time',
              Icons.calendar_today_rounded,
              textTheme,
              readOnly: true, // This field is read-only, opens picker on tap
              onTap: _selectDateTime,
            ),

            const SizedBox(height: 30),

            // 🔹 Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateRendezvous,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text('Save Changes', style: textTheme.labelLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}