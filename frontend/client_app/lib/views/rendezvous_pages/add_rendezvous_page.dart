import 'package:flutter/material.dart';
import 'package:client_app/services/rendezvous_services/add_rendezvous.dart';
import 'package:client_app/views/components/home_navbar.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/services/vet_services/veterinaire_service.dart';
import 'package:client_app/models/vet_models/veterinaire.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddRendezvousPage extends StatefulWidget {
  const AddRendezvousPage({Key? key}) : super(key: key);

  @override
  State<AddRendezvousPage> createState() => _AddRendezvousPageState();
}

class _AddRendezvousPageState extends State<AddRendezvousPage> {
  final TextEditingController _dateController = TextEditingController();

  List<Animal> _animals = [];
  List<Veterinaire> _veterinaires = [];
  Animal? _selectedAnimal;
  Veterinaire? _selectedVeterinaire;
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
      final vets = await VeterinaireService().getAllVeterinaires();

      setState(() {
        _animals = animals;
        _veterinaires = vets;
        _isLoading = false;

        if (_animals.isNotEmpty) {
          _selectedAnimal = _animals.first;
        }
        if (_veterinaires.isNotEmpty) {
          _selectedVeterinaire = _veterinaires.first;
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
          _dateController.text = '${selectedDateTime.toLocal()}'.split('.')[0];
        });
      }
    }
  }

  void _addRendezvous() async {
    if (_selectedAnimal == null ||
        _selectedVeterinaire == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final data = {
      "AnimalId": _selectedAnimal!.id,
      "VetId": _selectedVeterinaire!.username,
      "Date": _selectedDateTime!.toIso8601String(),
    };

    try {
      await AddRendezvousService().addRendezvous(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous ajouté')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: _username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
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
                    'Ajouter un Rendez-vous',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        const InputDecoration(labelText: 'Nom de l\'animal'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Veterinaire>(
                    value: _selectedVeterinaire,
                    items: _veterinaires
                        .map((vet) => DropdownMenuItem(
                              value: vet,
                              child: Text((vet.firstName.isNotEmpty &&
                                      vet.lastName.isNotEmpty)
                                  ? '${vet.firstName} ${vet.lastName}'
                                  : vet.username),
                            ))
                        .toList(),
                    onChanged: (vet) {
                      setState(() {
                        _selectedVeterinaire = vet;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Nom du vétérinaire'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date et heure',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _selectDateTime,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addRendezvous,
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
      ),
    );
  }
}
