import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/utils/base_url.dart';
import '../../models/profile_models/profile_model.dart';
import '../../services/profile_services/edit_profile_service.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart';

import '../../utils/app_colors.dart'; // Adjust path if using a separate constants.dart file

class ProfileEditPage extends StatefulWidget {
  final ProfileModel profile;
  final String jwtToken;

  const ProfileEditPage({
    Key? key,
    required this.profile,
    required this.jwtToken,
  }) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _zipCodeController;
  late TextEditingController _emailController;
  late String _gender;
  DateTime? _selectedBirthDate;

  late EditProfileService profileService;
  bool _isSaving = false; // Added to manage saving state and show loading indicator

  @override
  void initState() {
    super.initState();
    profileService = EditProfileService(
      editProfileUrl: "${BaseUrl.api}/api/veterinaire/profile/update-profile",
    );

    _userNameController = TextEditingController(text: widget.profile.userName);
    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneNumberController = TextEditingController(
      text: widget.profile.phoneNumber,
    );

    try {
      _selectedBirthDate = DateTime.parse(widget.profile.birthDate);
      _birthDateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
      );
    } catch (_) {
      _birthDateController = TextEditingController();
    }

    _addressController = TextEditingController(text: widget.profile.address);
    _zipCodeController = TextEditingController(text: widget.profile.zipCode);
    _emailController = TextEditingController(text: widget.profile.email);
    _gender = widget.profile.gender.isNotEmpty ? widget.profile.gender : 'male'; // Ensure a default value
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
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
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          'Edit Profile',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), // Consistent padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Details Section
              Text(
                "Account Details",
                style: textTheme.headlineSmall?.copyWith(
                  // Use themed headlineSmall
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen, // Themed section title
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                textTheme, // Pass textTheme
                _userNameController,
                "Username",
                Icons.person_outline_rounded, // Modern icon
              ),
              _buildTextField(
                textTheme, // Pass textTheme
                _firstNameController,
                "First Name",
                Icons.person_outline_rounded,
              ),
              _buildTextField(
                textTheme, // Pass textTheme
                _lastNameController,
                "Last Name",
                Icons.person_outline_rounded,
              ),

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: Icon(Icons.wc_rounded, color: kAccentGreen), // Modern icon, themed color
                    // Input decoration handled by InputDecorationTheme in main.dart
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'IDK', child: Text('Prefer not to say')), // More user-friendly option
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Gender is required'
                      : null,
                  style: textTheme.bodyLarge, // Use themed bodyLarge for dropdown text
                  dropdownColor: Theme.of(context).cardTheme.color, // Themed dropdown background
                ),
              ),

              // Birth Date Picker
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: kPrimaryGreen, // Header background color
                              onPrimary: Colors.white, // Header text color
                              onSurface: Colors.black87, // Body text color
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: kAccentGreen, // Button text color
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedBirthDate = pickedDate;
                        _birthDateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(pickedDate);
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Birth Date",
                    prefixIcon: Icon(Icons.calendar_today_rounded, color: kAccentGreen), // Modern icon, themed color
                    // Input decoration handled by InputDecorationTheme in main.dart
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Birth Date is required';
                    }
                    return null;
                  },
                  style: textTheme.bodyLarge, // Use themed bodyLarge
                ),
              ),

              const SizedBox(height: 32),

              // Contact Details Section
              Text(
                "Contact Details",
                style: textTheme.headlineSmall?.copyWith(
                  // Use themed headlineSmall
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen, // Themed section title
                ),
              ),
              const SizedBox(height: 20),

              // Email (read-only)
              _buildTextField(
                textTheme, // Pass textTheme
                _emailController,
                "Email",
                Icons.email_outlined,
                readOnly: true,
              ),
              _buildTextField(
                textTheme, // Pass textTheme
                _phoneNumberController,
                "Phone Number",
                Icons.phone_outlined,
              ),
              _buildTextField(textTheme, _addressController, "Address", Icons.home_outlined),
              _buildTextField(
                textTheme, // Pass textTheme
                _zipCodeController,
                "Zip Code",
                Icons.location_on_outlined,
              ),

              const SizedBox(height: 32),

              Center(
                child: _isSaving
                    ? Center(child: CircularProgressIndicator(color: kPrimaryGreen)) // Themed loading indicator
                    : ElevatedButton.icon(
                  // Button styling is handled by ElevatedButtonThemeData in main.dart
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateProfile();
                    }
                  },
                  icon: const Icon(Icons.save_rounded, color: Colors.white), // Modern save icon
                  label: Text(
                    'Update Profile',
                    style: textTheme.labelLarge, // Use themed labelLarge
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable text field builder with icons & style
  Widget _buildTextField(
      TextTheme textTheme, // Accept textTheme
      TextEditingController controller,
      String label,
      IconData icon, {
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: textTheme.bodyLarge, // Use themed bodyLarge for input text
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kAccentGreen), // Themed icon color
          // Input decoration handled by InputDecorationTheme in main.dart
        ),
        validator: (value) {
          if (value == null || value.isEmpty && !readOnly) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true; // Set saving state to true
    });

    try {
      final updatedProfile = {
        'userName': _userNameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'birthDate': _selectedBirthDate?.toUtc().toIso8601String() ?? '',
        'address': _addressController.text,
        'zipCode': _zipCodeController.text,
        'gender': _gender,
        'email': _emailController.text,
      };

      final isSuccess = await profileService.updateProfile(
        widget.jwtToken,
        updatedProfile,
      );

      if (isSuccess) {
        if (mounted) {
          Navigator.pop(context); // Pop back to profile page
          _showSnackBar('Profile updated successfully!', isSuccess: true);
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to update profile. Please try again.', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Reset saving state
        });
      }
    }
  }
}