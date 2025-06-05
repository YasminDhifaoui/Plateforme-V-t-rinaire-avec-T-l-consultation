import 'package:client_app/models/profile_models/profile_model.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:client_app/views/profile_pages/profile_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/services/profile_services/profile_service.dart';
import 'package:intl/intl.dart';
import 'package:client_app/services/animal_services/animal_service.dart';
import 'package:client_app/models/animals_models/animal.dart';
import 'package:client_app/services/auth_services/token_service.dart'; // <--- Import TokenService
import '../../utils/app_colors.dart'; // Import for kPrimaryBlue, kAccentBlue

import 'package:client_app/main.dart'; // For kPrimaryBlue, kAccentBlue

import 'package:client_app/views/profile_pages/client_change_password_page.dart'; // <--- Import ClientChangePasswordPage

class ProfilePage extends StatefulWidget {
  // Remove the jwtToken parameter from here
  // final String jwtToken; // REMOVED

  // Add an optional parameter to receive the success flag for password change
  final bool passwordChangedSuccessfully;

  const ProfilePage({
    Key? key,
    // Key? key, required this.jwtToken // REMOVED
    this.passwordChangedSuccessfully = false, // Default to false
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileModel? _profile;
  List<Animal> _animals = [];
  bool isLoading = true;
  String errorMessage = '';
  String? _jwtToken; // <--- Store token here

  late ProfileService profileService;
  final AnimalService _animalService = AnimalService();

  @override
  void initState() {
    super.initState();
    profileService = ProfileService(
      profileUrl: "${BaseUrl.api}/api/client/profile/see-profile",
    );
    _initializeProfileAndAnimals(); // Call a new method to handle token retrieval
  }

  // New method to handle token retrieval and initial data fetch
  Future<void> _initializeProfileAndAnimals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      _jwtToken = await TokenService.getToken(); // Retrieve token here
      if (_jwtToken == null) {
        throw Exception('Authentication token missing. Please log in.');
      }
      await _fetchProfileAndAnimals(); // Now call the fetch method

      // Check if password was changed successfully and show dialog
      if (widget.passwordChangedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPasswordChangedSuccessDialog();
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Initialization Error: $e';
        isLoading = false;
      });
      _showSnackBar('Initialization Error: $e', isSuccess: false);
    }
  }

  // Modified fetch method to use the internally stored token
  Future<void> _fetchProfileAndAnimals() async {
    if (_jwtToken == null) {
      setState(() {
        errorMessage = 'JWT Token is not available. Please log in.';
        isLoading = false;
      });
      return;
    }

    try {
      final profileData = await profileService.fetchProfile(_jwtToken!);
      // Assuming getAnimalsList also uses the TokenService internally or doesn't need a token
      final animalsData = await _animalService.getAnimalsList();

      setState(() {
        _profile = profileData;
        _animals = animalsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile or animals: $e';
        isLoading = false;
      });
      _showSnackBar('Failed to load profile or animals: $e', isSuccess: false);
    }
  }

  // New method to show the password changed success dialog
  void _showPasswordChangedSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: kPrimaryBlue, size: 30),
              SizedBox(width: 10),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: kPrimaryBlue),
              ),
            ],
          ),
          content: Text(
            'Your password has been changed successfully.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: kPrimaryBlue),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

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


  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(color: kPrimaryBlue),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeProfileAndAnimals, // Retry initialization
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Retry', style: textTheme.labelLarge),
              ),
            ],
          ),
        ),
      )
          : _profile == null
          ? Center(
        child: Text(
          'No profile data available.',
          style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kAccentBlue, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/pet_owner.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: 90,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profile!.userName,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _contactInfoRow(
                                Icons.email_outlined,
                                _profile!.email,
                                textTheme,
                              ),
                              const SizedBox(height: 6),
                              _contactInfoRow(
                                Icons.phone_outlined,
                                _profile!.phoneNumber,
                                textTheme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Personal Information',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _infoRow(context, Icons.person_outline, 'First Name', _profile!.firstName),
                    _themedDivider(),
                    _infoRow(context, Icons.person_outline, 'Last Name', _profile!.lastName),
                    _themedDivider(),
                    _infoRow(context, Icons.transgender, 'Gender', _profile!.gender),
                    _themedDivider(),
                    _infoRow(context, Icons.cake_outlined, 'Date of Birth', _profile!.birthDate),
                    _themedDivider(),
                    _infoRow(context, Icons.home_outlined, 'Address', _profile!.address),
                    _themedDivider(),
                    _infoRow(context, Icons.markunread_mailbox_outlined, 'Zip Code', _profile!.zipCode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'My Animals',
              style: textTheme.titleLarge?.copyWith(
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _animals.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No animals registered yet.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _animals.length,
              itemBuilder: (context, index) {
                final animal = _animals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: kAccentBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimalDetailRow(textTheme, Icons.category_rounded, 'Species', animal.espece),
                        _buildAnimalDetailRow(textTheme, Icons.pets_rounded, 'Breed', animal.race),
                        _buildAnimalDetailRow(textTheme, Icons.calendar_month_rounded, 'Age', '${animal.age} years'),
                        _buildAnimalDetailRow(textTheme, Icons.transgender_rounded, 'Gender', animal.sexe),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: kPrimaryBlue.withOpacity(0.4),
                ),
                onPressed: () {
                  if (_profile != null && _jwtToken != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditPage(
                          profile: _profile!,
                          jwtToken: _jwtToken!, // Pass the internally retrieved token
                        ),
                      ),
                    ).then((_) => _initializeProfileAndAnimals()); // Refresh after edit
                  } else {
                    _showSnackBar('Profile data or token not available for editing.', isSuccess: false);
                  }
                },
                child: Text(
                  'Edit Profile',
                  style: textTheme.labelLarge?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor: kAccentBlue.withOpacity(0.4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientChangePasswordPage(), // Navigate to the client change password page
                    ),
                  );
                },
                child: Text(
                  'Change Password',
                  style: textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _contactInfoRow(IconData icon, String value, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentBlue),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    value = value.isEmpty ? 'Not provided' : value;

    if (label == 'Date of Birth') {
      try {
        DateTime birthDate = DateTime.parse(value);
        value = DateFormat('dd/MM/yyyy').format(birthDate);
      } catch (e) {
        value = 'Invalid date';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kAccentBlue, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalDetailRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _themedDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: kAccentBlue,
      ),
    );
  }
}