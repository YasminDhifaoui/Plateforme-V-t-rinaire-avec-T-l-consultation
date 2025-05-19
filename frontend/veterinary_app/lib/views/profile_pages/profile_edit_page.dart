import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/profile_models/profile_model.dart';
import '../../services/profile_services/edit_profile_service.dart';

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

  @override
  void initState() {
    super.initState();
    profileService = EditProfileService(
      editProfileUrl: "http://10.0.2.2:5000/api/client/profile/update-profile",
    );

    _userNameController = TextEditingController(text: widget.profile.userName);
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneNumberController = TextEditingController(text: widget.profile.phoneNumber);

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
    _gender = widget.profile.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Details Section
                Text(
                  "Account Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_userNameController, "Username", Icons.person),
                _buildTextField(_firstNameController, "First Name", Icons.person_outline),
                _buildTextField(_lastNameController, "Last Name", Icons.person_outline),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _gender.isEmpty ? 'male' : _gender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Icons.wc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'IDK', child: Text('IDK')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Gender is required' : null,
                ),
                const SizedBox(height: 16),

                // Birth Date Picker
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedBirthDate = pickedDate;
                        _birthDateController.text =
                            DateFormat('dd/MM/yyyy').format(pickedDate);
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Birth Date",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Birth Date is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Contact Details Section
                Text(
                  "Contact Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                // Email (read-only)
                _buildTextField(_emailController, "Email", Icons.email, readOnly: true),
                _buildTextField(_phoneNumberController, "Phone Number", Icons.phone),
                _buildTextField(_addressController, "Address", Icons.home),
                _buildTextField(_zipCodeController, "Zip Code", Icons.location_pin),

                const SizedBox(height: 32),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 50),
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.green.shade300,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _updateProfile();
                      }
                    },
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable text field builder with icons & style
  Widget _buildTextField(
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
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _updateProfile() async {
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
