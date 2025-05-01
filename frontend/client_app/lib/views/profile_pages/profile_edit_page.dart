import 'package:client_app/models/profile_models/profile_model.dart';
import 'package:flutter/material.dart';
import '../../services/profile_services/edit_profile_service.dart'; // Import EditProfileService

class ProfileEditPage extends StatefulWidget {
  final ProfileModel profile;
  final String jwtToken;

  const ProfileEditPage(
      {Key? key, required this.profile, required this.jwtToken})
      : super(key: key);

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
  late TextEditingController _emailController; // Add controller for email
  late String _gender;

  late EditProfileService profileService;

  @override
  void initState() {
    super.initState();
    profileService = EditProfileService(
      editProfileUrl: "http://10.0.2.2:5000/api/client/profile/update-profile",
    );

    _userNameController = TextEditingController(text: widget.profile.userName);
    _firstNameController =
        TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneNumberController =
        TextEditingController(text: widget.profile.phoneNumber);
    _birthDateController =
        TextEditingController(text: widget.profile.birthDate);
    _addressController = TextEditingController(text: widget.profile.address);
    _zipCodeController = TextEditingController(text: widget.profile.zipCode);
    _emailController = TextEditingController(text: widget.profile.email);
    _gender = widget.profile.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_userNameController, 'Username'),
                _buildTextField(_firstNameController, 'First Name'),
                _buildTextField(_lastNameController, 'Last Name'),
                _buildTextField(_phoneNumberController, 'Phone Number'),
                _buildTextField(_birthDateController, 'Birth Date'),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_zipCodeController, 'Zip Code'),
                _buildTextField(
                    _emailController, 'Email'), // Add email input field
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _gender.isEmpty
                      ? 'male'
                      : _gender, // Set default value if _gender is empty
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
                  decoration: const InputDecoration(labelText: 'Gender'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Gender is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateProfile();
                    }
                  },
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create text fields
  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _updateProfile() async {
    try {
      final updatedProfile = {
        'userName': _userNameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'birthDate': _birthDateController.text,
        'address': _addressController.text,
        'zipCode': _zipCodeController.text,
        'gender': _gender,
        'email': _emailController.text, // Pass the email value
      };

      final isSuccess = await profileService.updateProfile(
        widget.jwtToken,
        updatedProfile,
      );

      if (isSuccess) {
        // Successfully updated, return to the previous page
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        // Failed to update, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update profile. Please try again.')),
        );
      }
    } catch (e) {
      // Handle any error that occurs during the update process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
