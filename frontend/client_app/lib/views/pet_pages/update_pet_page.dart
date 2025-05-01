import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/home_navbar.dart';
import '../../utils/logout_helper.dart';
import '../../models/animals_models/animal.dart';
import '../../services/animal_services/animal_update_service.dart';

class UpdatePetPage extends StatefulWidget {
  final Animal animal;

  const UpdatePetPage({Key? key, required this.animal}) : super(key: key);

  @override
  State<UpdatePetPage> createState() => _UpdatePetPageState();
}

class _UpdatePetPageState extends State<UpdatePetPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _allergiesController;
  late TextEditingController _antecedentsController;

  String username = '';
  final AnimalUpdateService animalUpdateService = AnimalUpdateService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal.name);
    _ageController = TextEditingController(text: widget.animal.age.toString());
    _allergiesController = TextEditingController(text: widget.animal.allergies);
    _antecedentsController = TextEditingController(text: widget.animal.antecedentsmedicaux);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _antecedentsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await animalUpdateService.updateAnimal(
          id: widget.animal.id,
          name: _nameController.text,
          age: int.parse(_ageController.text),
          allergies: _allergiesController.text,
          antecedentsmedicaux: _antecedentsController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet updated successfully')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pet: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Back to Pet List',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter name' : null,
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter age';
                        if (int.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(labelText: 'Allergies'),
                    ),
                    TextFormField(
                      controller: _antecedentsController,
                      decoration: const InputDecoration(labelText: 'Antecedents Medicaux'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Update Pet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
