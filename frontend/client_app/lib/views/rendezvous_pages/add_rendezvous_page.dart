import 'package:flutter/material.dart';
import 'package:client_app/services/rendezvous_services/add_rendezvous.dart';
import 'package:client_app/views/components/home_navbar.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/models/vet_models/veterinaire.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_services/token_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    }
  }

  Future<void> _selectDateTime() async {
    DateTime initialDate = _selectedDateTime ?? DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
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
          _dateController.text =
          '${selectedDateTime.toLocal()}'.split('.')[0];
        });
      }
    }
  }

  void _addRendezvous() async {
    if (_selectedAnimal == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final clientId = await TokenService.getUserId();

    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié')),
      );
      return;
    }

    Map<String, dynamic> data = {
      "animalId": _selectedAnimal!.id.toString(),
      "vetId": widget.vet.id,
      "date": _selectedDateTime!.toIso8601String(),
    };


    print("Sending vetId: ${widget.vet.id.runtimeType} = ${widget.vet.id}");



    try {
      await AddRendezvousService().addRendezvous(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous ajouté avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erreur lors de l\'ajout du rendez-vous : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vet = widget.vet;

    return Scaffold(
      appBar: HomeNavbar(
        username: _username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Appointment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Vet details
              Text(
                'Veterinarian Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text('Name: ${vet.firstName} ${vet.lastName}'),
              Text('Username: ${vet.username}'),
              Text('Email: ${vet.email}'),
              Text('Phone: ${vet.phoneNumber}'),

              const SizedBox(height: 20),

              // Animal dropdown
              DropdownButtonFormField<Animal>(
                value: _selectedAnimal,
                items: _animals
                    .map((animal) => DropdownMenuItem(
                  value: animal,
                  child: Text(animal.name),
                ))
                    .toList(),
                onChanged: (animal) {
                  setState(() {
                    _selectedAnimal = animal;
                  });
                },
                decoration:
                const InputDecoration(labelText: 'Animal name'),
              ),
              const SizedBox(height: 16),

              // Date/time picker
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date and Time',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                onPressed: _addRendezvous,
                child: const Text('Save Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
