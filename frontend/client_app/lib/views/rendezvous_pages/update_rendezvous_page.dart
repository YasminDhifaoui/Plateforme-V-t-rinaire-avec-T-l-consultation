import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_app/models/rendezvous_models/rendezvous.dart';
import 'package:client_app/services/rendezvous_services/update_rendezvous.dart';
import 'package:client_app/views/components/home_navbar.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/services/vet_services/veterinaire_service.dart';
import 'package:client_app/models/vet_models/veterinaire.dart';

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
              (a) => a.name.toLowerCase().trim() == rendezvous.animalName.toLowerCase().trim(),
          orElse: () {
            print('Animal not found: ${rendezvous.animalName}');
            return animals.first;
          },
        );


        _selectedVeterinaire = vets.firstWhere(
              (v) => v.username == (passedVetName ?? rendezvous.vetName),
          orElse: () => vets.first,
        );
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
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
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(rendezvous.date),
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
    final vetIdToSend = _selectedVeterinaire?.id;
    if (vetIdToSend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: vétérinaire introuvable')),
      );
      return;
    }

    final data = {
      "animalId": _selectedAnimal?.id, // ✅ Send the animal's ID here
      "vetId": vetIdToSend,
      "date": DateFormat('yyyy-MM-ddTHH:mm:ss')
          .format(DateFormat('dd-MM-yyyy HH:mm').parse(_dateController.text)),
      "status": rendezvous.status.name,
    };

    print('Sending data: $data');

    try {
      await UpdateRendezvousService().updateRendezvous(rendezvous.id, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous mis à jour')),
      );
      Navigator.pop(context, true); // <- send 'true' to indicate successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de mise à jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: '',
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 🔹 Animal Dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Nom de l\'animal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.pets),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Animal>(
                  isExpanded: true,
                  value: _selectedAnimal,
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
            TextFormField(
              initialValue: _selectedVeterinaire != null
                  ? (_selectedVeterinaire!.firstName.isNotEmpty &&
                  _selectedVeterinaire!.lastName.isNotEmpty
                  ? '${_selectedVeterinaire!.firstName} ${_selectedVeterinaire!.lastName}'
                  : _selectedVeterinaire!.username)
                  : rendezvous.vetName,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Vétérinaire',
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Date and Time Picker
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date et Heure',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onTap: _selectDateTime,
            ),

            const SizedBox(height: 30),

            // 🔹 Save Button
            ElevatedButton.icon(
              onPressed: _updateRendezvous,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
