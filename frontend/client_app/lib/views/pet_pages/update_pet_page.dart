import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../components/home_navbar.dart'; // Replaced with standard AppBar for this page
import '../../utils/logout_helper.dart'; // Keep if used for general logout logic
import '../../models/animals_models/animal.dart';
import '../../services/animal_services/animal_update_service.dart';

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

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

  // We don't need username here as HomeNavbar is removed and username is not displayed on this page
  // String username = '';

  final AnimalUpdateService animalUpdateService = AnimalUpdateService();
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal.name);
    _ageController = TextEditingController(text: widget.animal.age.toString());
    _allergiesController = TextEditingController(text: widget.animal.allergies);
    _antecedentsController = TextEditingController(text: widget.animal.antecedentsmedicaux);
    // _loadUserData(); // No longer needed as username is not directly used on this page
  }

  // No longer needed as username is not directly used on this page
  // Future<void> _loadUserData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     username = prefs.getString('username') ?? '';
  //   });
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Set loading true
      });
      try {
        await animalUpdateService.updateAnimal(
          id: widget.animal.id,
          name: _nameController.text,
          age: int.parse(_ageController.text),
          allergies: _allergiesController.text,
          antecedentsmedicaux: _antecedentsController.text,
        );
        _showSnackBar('Pet updated successfully!', isSuccess: true);
        Navigator.pop(context, true); // Pop with true to indicate success for refresh
      } catch (e) {
        _showSnackBar('Failed to update pet: $e', isSuccess: false);
      } finally {
        setState(() {
          _isLoading = false; // Set loading false
        });
      }
    }
  }

  // Reusable text field builder with themed icons & style (copied from AddPetPage for consistency)
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      TextTheme textTheme, {
        bool isOptional = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        bool readOnly = false, // Added readOnly parameter
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly, // Apply readOnly property
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
          'Edit Pet: ${widget.animal.name}', // Dynamic title
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
                "Pet Information",
                style: textTheme.headlineSmall?.copyWith(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Name (editable)
              _buildTextField(_nameController, "Name", Icons.pets_rounded, textTheme),
              // Species (read-only)
              _buildTextField(
                TextEditingController(text: widget.animal.espece), // Use a new controller for read-only
                "Species",
                Icons.category_rounded,
                textTheme,
                readOnly: true,
              ),
              // Breed (read-only)
              _buildTextField(
                TextEditingController(text: widget.animal.race), // Use a new controller for read-only
                "Breed",
                Icons.track_changes_rounded,
                textTheme,
                readOnly: true,
              ),
              // Age (editable)
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
              // Sex (read-only)
              _buildTextField(
                TextEditingController(text: widget.animal.sexe), // Use a new controller for read-only
                "Sex",
                Icons.transgender_rounded,
                textTheme,
                readOnly: true,
              ),
              // Allergies (editable, optional)
              _buildTextField(
                _allergiesController,
                "Allergies",
                Icons.medical_services_rounded,
                textTheme,
                isOptional: true,
              ),
              // Medical History (editable, optional)
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
                    onPressed: _submitForm,
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
                      'Update Pet',
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