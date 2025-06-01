// veterinary_app/views/animals_pages/animal_edit_page.dart

import 'package:flutter/material.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/models/animal_models/update_animal_vet_dto.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/main.dart';

import '../../utils/app_colors.dart'; // For kPrimaryGreen, kAccentGreen

class AnimalEditPage extends StatefulWidget {
  final AnimalModel animal;
  final String jwtToken;

  const AnimalEditPage({
    super.key,
    required this.animal,
    required this.jwtToken,
  });

  @override
  State<AnimalEditPage> createState() => _AnimalEditPageState();
}

class _AnimalEditPageState extends State<AnimalEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController antecedentsMedicauxController = TextEditingController();

  final AnimalsVetService _animalService = AnimalsVetService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers with existing animal data
    ageController.text = widget.animal.age.toString();
    allergiesController.text = widget.animal.allergies;
    antecedentsMedicauxController.text = widget.animal.anttecedentsmedicaux;
  }

  @override
  void dispose() {
    ageController.dispose();
    allergiesController.dispose();
    antecedentsMedicauxController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
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

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final updateDto = UpdateAnimalVetDto(
        age: int.parse(ageController.text.trim()),
        allergies: allergiesController.text.trim(),
        antecedentsMedicaux: antecedentsMedicauxController.text.trim(),
      );

      final result = await _animalService.updateAnimal(
        widget.animal.id.toString(), // Ensure ID is sent as string if backend expects it
        updateDto,
        widget.jwtToken,
      );

      if (result["success"] == true) {
        _showSnackBar(result["message"] ?? "Animal updated successfully!", isSuccess: true);
        Navigator.pop(context, true); // Pop with true to indicate success
      } else {
        _showSnackBar(result["message"] ?? "Failed to update animal.", isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number for age';
    }
    if (int.parse(value) <= 0) {
      return 'Age must be positive';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Edit ${widget.animal.name}',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 70,
                    color: kPrimaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Animal Details',
                    style: textTheme.headlineSmall?.copyWith(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age (Years)',
                      prefixIcon: Icon(Icons.cake_rounded, color: kAccentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimaryGreen, width: 2), borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: _validateAge,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: allergiesController,
                    decoration: InputDecoration(
                      labelText: 'Allergies (e.g., pollen, certain foods)',
                      prefixIcon: Icon(Icons.medical_services_rounded, color: kAccentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimaryGreen, width: 2), borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: antecedentsMedicauxController,
                    decoration: InputDecoration(
                      labelText: 'Medical History (e.g., previous conditions, surgeries)',
                      prefixIcon: Icon(Icons.history_edu_rounded, color: kAccentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimaryGreen, width: 2), borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: kPrimaryGreen))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitUpdate,
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        'Save Changes',
                        style: textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
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
          ),
        ),
      ),
    );
  }
}