import 'package:client_app/services/animal_services/animal_add_service.dart';
import 'package:flutter/material.dart';
// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

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
  bool _isLoading = false; // Add loading state

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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Set loading true
      });
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

        _showSnackBar('Pet added successfully!', isSuccess: true);
        Navigator.pop(context, true); // Pop with true to indicate success for refresh
      } catch (e) {
        _showSnackBar('Error adding pet: $e', isSuccess: false);
      } finally {
        setState(() {
          _isLoading = false; // Set loading false
        });
      }
    }
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
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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
            ? null // No validation if optional
            : validator ??
                (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
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
          'Add a New Pet', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pet Details",
                style: textTheme.headlineSmall?.copyWith(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nameController, "Name", Icons.pets_rounded, textTheme),
              _buildTextField(_especeController, "Species", Icons.category_rounded, textTheme),
              _buildTextField(_raceController, "Breed", Icons.track_changes_rounded, textTheme),
              _buildTextField(
                _ageController,
                "Age",
                Icons.cake_rounded,
                textTheme,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number for age';
                  }
                  return null;
                },
              ),
              _buildTextField(_sexeController, "Sex", Icons.transgender_rounded, textTheme),
              _buildTextField(
                _allergiesController,
                "Allergies",
                Icons.medical_services_rounded,
                textTheme,
                isOptional: true,
              ),
              _buildTextField(
                _antecedentsController,
                "Medical History",
                Icons.history_edu_rounded,
                textTheme,
                isOptional: true,
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity, // Make button full width
                  child: _isLoading
                      ? CircularProgressIndicator(color: kPrimaryBlue) // Themed loading indicator
                      : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6, // Add subtle shadow
                    ),
                    child: Text(
                      'Save Pet',
                      style: textTheme.labelLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}