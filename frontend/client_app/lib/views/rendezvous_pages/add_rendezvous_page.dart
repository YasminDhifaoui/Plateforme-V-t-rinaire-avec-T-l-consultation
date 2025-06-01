import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for date formatting
import 'package:client_app/services/rendezvous_services/add_rendezvous.dart';
// import 'package:client_app/views/components/home_navbar.dart'; // Replaced with standard AppBar
// import 'package:client_app/utils/logout_helper.dart'; // Keep if needed for general logout logic
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/models/vet_models/veterinaire.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_services/token_service.dart';
import 'package:client_app/main.dart'; // Import for kPrimaryBlue, kAccentBlue

class AddRendezvousPage extends StatefulWidget {
  final Veterinaire vet;

  const AddRendezvousPage({Key? key, required this.vet}) : super(key: key);

  @override
  State<AddRendezvousPage> createState() => _AddRendezvousPageState();
}

class _AddRendezvousPageState extends State<AddRendezvousPage> {
  final TextEditingController _dateController = TextEditingController();

  List<Animal> _animals = [];
  Animal? _selectedAnimal;
  DateTime? _selectedDateTime;
  bool _isLoading = true;

  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadData();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    setState(() {
      _username = username;
    });
  }

  Future<void> _loadData() async {
    try {
      final animals = await AnimalService().getAnimalsList();
      setState(() {
        _animals = animals;
        _isLoading = false;

        if (_animals.isNotEmpty) {
          _selectedAnimal = _animals.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data: $e', isSuccess: false);
    }
  }

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
        initialTime: TimeOfDay.fromDateTime(initialDate),
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
          _selectedDateTime = selectedDateTime;
          _dateController.text = DateFormat('dd MMM yyyy HH:mm').format(selectedDateTime);
        });
      }
    }
  }

  void _addRendezvous() async {
    if (_selectedAnimal == null || _selectedDateTime == null) {
      _showSnackBar('Please fill in all fields.', isSuccess: false);
      return;
    }

    final clientId = await TokenService.getUserId();

    if (clientId == null) {
      _showSnackBar('User not authenticated.', isSuccess: false);
      return;
    }

    // Ensure date is in ISO 8601 format for backend
    final formattedDate = _selectedDateTime!.toIso8601String();

    Map<String, dynamic> data = {
      "animalId": _selectedAnimal!.id.toString(),
      "vetId": widget.vet.id,
      "date": formattedDate,
    };

    print("Sending vetId: ${widget.vet.id.runtimeType} = ${widget.vet.id}"); // Debugging


    try {
      await AddRendezvousService().addRendezvous(data);
      _showSnackBar('Appointment added successfully!', isSuccess: true);
      Navigator.pop(context,true); // Go back to the previous page (RendezvousPage)
    } catch (e) {
      _showSnackBar('Error adding appointment: ${e.toString()}', isSuccess: false);
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final vet = widget.vet;

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
          'Schedule Appointment', // Clearer, themed title
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

            const SizedBox(height: 25),

            // Veterinarian Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veterinarian Information:',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kAccentBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(textTheme, Icons.badge_outlined, 'Name', vet.username),
                    _buildInfoRow(textTheme, Icons.email_outlined, 'Email', vet.email),
                    _buildInfoRow(textTheme, Icons.phone_outlined, 'Phone', vet.phoneNumber),
                    _buildInfoRow(textTheme, Icons.place_outlined, 'Address', vet.address),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Animal Dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Select Your Animal',
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

            // Date/Time Picker
            TextFormField(
              controller: _dateController,
              readOnly: true,
              style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Select Date and Time',
                labelStyle: TextStyle(color: kPrimaryBlue),
                prefixIcon: Icon(Icons.calendar_today_rounded, color: kAccentBlue),
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
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addRendezvous,
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: Text('Confirm Appointment', style: textTheme.labelLarge),
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

  // Helper for info rows within the Vet Details card
  Widget _buildInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}