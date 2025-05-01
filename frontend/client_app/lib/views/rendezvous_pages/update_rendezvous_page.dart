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
          (a) => a.name == rendezvous.animalName,
          orElse: () => animals.first,
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
    print('Date picker tapped');
    DateTime initialDate = rendezvous.date.isBefore(DateTime.now())
        ? DateTime.now()
        : rendezvous.date;
    print('Initial date for picker: $initialDate');

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
    String? vetNameToSend =
        _selectedVeterinaire?.username ?? rendezvous.vetName;
    print('Updating rendezvous with vetName: $vetNameToSend');

    if (vetNameToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: vétérinaire non sélectionné')),
      );
      return;
    }

    final data = {
      "animalName": _selectedAnimal?.name ?? rendezvous.animalName,
      "vetName": vetNameToSend,
      "date": DateFormat('yyyy-MM-ddTHH:mm:ss')
          .format(DateFormat('dd-MM-yyyy HH:mm').parse(_dateController.text)),
      "status": rendezvous.status.name,
    };

    try {
      await UpdateRendezvousService().updateRendezvous(rendezvous.id, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous mis à jour')),
      );
      Navigator.pop(context);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                    onPressed: _updateRendezvous,
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
      ),
    );
  }
}
