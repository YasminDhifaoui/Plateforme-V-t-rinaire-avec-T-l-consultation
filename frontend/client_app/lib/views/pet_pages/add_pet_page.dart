import 'package:client_app/services/animal_services/animal_add_service.dart';
import 'package:flutter/material.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({Key? key}) : super(key: key);

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _especeController = TextEditingController();
  final _raceController = TextEditingController();
  final _ageController = TextEditingController();
  final _sexeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _antecedentsController = TextEditingController();

  final AnimalAddService animalAddService = AnimalAddService();

  @override
  void dispose() {
    _nameController.dispose();
    _especeController.dispose();
    _raceController.dispose();
    _ageController.dispose();
    _sexeController.dispose();
    _allergiesController.dispose();
    _antecedentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await animalAddService.addAnimal(
          name: _nameController.text.trim(),
          espece: _especeController.text.trim(),
          race: _raceController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          sexe: _sexeController.text.trim(),
          allergies: _allergiesController.text.trim(),
          antecedentsmedicaux: _antecedentsController.text.trim(),
        );

        Navigator.pop(context); // go back after adding
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter name' : null,
              ),
              TextFormField(
                controller: _especeController,
                decoration: const InputDecoration(labelText: 'Espece'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter espece' : null,
              ),
              TextFormField(
                controller: _raceController,
                decoration: const InputDecoration(labelText: 'Race'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter race' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter age' : null,
              ),
              TextFormField(
                controller: _sexeController,
                decoration: const InputDecoration(labelText: 'Sexe'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter sexe' : null,
              ),
              TextFormField(
                controller: _allergiesController,
                decoration:
                    const InputDecoration(labelText: 'Allergies (optional)'),
              ),
              TextFormField(
                controller: _antecedentsController,
                decoration: const InputDecoration(
                    labelText: 'Antecedents Medicaux (optional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
