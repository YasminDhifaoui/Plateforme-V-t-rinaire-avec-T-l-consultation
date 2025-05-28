import 'package:client_app/models/profile_models/profile_model.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:client_app/views/profile_pages/profile_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/services/profile_services/profile_service.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:client_app/services/animal_services/animal_service.dart'; // Import AnimalService
import 'package:client_app/models/animals_models/animal.dart'; // Import Animal model

// Import the blue color constants from main.dart
import 'package:client_app/main.dart';

import '../Auth_pages/client_reset_password_page.dart';

class ProfilePage extends StatefulWidget {
  final String jwtToken;

  const ProfilePage({Key? key, required this.jwtToken}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileModel? _profile;
  List<Animal> _animals = []; // To store the user's animals
  bool isLoading = true;
  String errorMessage = '';

  late ProfileService profileService;
  final AnimalService _animalService = AnimalService(); // Initialize AnimalService

  @override
  void initState() {
    super.initState();
    profileService = ProfileService(
      profileUrl: "${BaseUrl.api}/api/client/profile/see-profile",
    );
    _fetchProfileAndAnimals(); // Fetch both profile and animals
  }

  Future<void> _fetchProfileAndAnimals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final profileData = await profileService.fetchProfile(widget.jwtToken);
      final animalsData = await _animalService.getAnimalsList(); // Fetch animals

      setState(() {
        _profile = profileData;
        _animals = animalsData; // Assign fetched animals
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile or animals: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Use primary blue
        foregroundColor: Colors.white, // White icons/text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back arrow
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile', // More personal title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true, // Center the title
        elevation: 0, // No shadow
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
            color: kPrimaryBlue), // Themed loading indicator
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded, // Error icon
                color: Colors.red.shade400,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge
                    ?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProfileAndAnimals, // Retry fetching the profile and animals
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue, // Themed button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
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
          style: textTheme.bodyLarge
              ?.copyWith(color: Colors.black54),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20), // Slightly reduced overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 10, // Increased elevation for more depth
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // More rounded corners
              ),
              // Use a very light blue for the card background
              child: Padding(
                padding: const EdgeInsets.all(28), // Increased padding inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header: picture + username + email + phone
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 90, // Larger profile picture
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: kAccentBlue,
                                width: 3), // Thicker, accent blue border
                            boxShadow: const [
                              // Subtle shadow for the image
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
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: 90,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 24), // Increased spacing
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profile!.userName,
                                style: textTheme.headlineSmall
                                    ?.copyWith(
                                  // Use theme for username
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8), // Spacing
                              _contactInfoRow(
                                Icons.email_outlined,
                                _profile!.email,
                                textTheme,
                              ),
                              const SizedBox(height: 6), // Spacing
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

                    const SizedBox(height: 40), // More spacing before personal info

                    Text(
                      'Personal Information',
                      style: textTheme.titleLarge?.copyWith(
                        // Use theme for section title
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20), // Spacing

                    _infoRow(context, Icons.person_outline,
                        'First Name', _profile!.firstName),
                    _themedDivider(), // Custom divider
                    _infoRow(context, Icons.person_outline,
                        'Last Name', _profile!.lastName),
                    _themedDivider(),
                    _infoRow(context, Icons.transgender,
                        'Gender', _profile!.gender),
                    _themedDivider(),
                    _infoRow(context, Icons.cake_outlined,
                        'Date of Birth', _profile!.birthDate),
                    _themedDivider(),
                    _infoRow(context, Icons.home_outlined,
                        'Address', _profile!.address),
                    _themedDivider(),
                    _infoRow(context, Icons.markunread_mailbox_outlined,
                        'Zip Code', _profile!.zipCode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- My Animals Section ---
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
                style: textTheme.bodyLarge
                    ?.copyWith(color: Colors.black54),
              ),
            )
                : ListView.builder(
              shrinkWrap: true, // Important for nested list views
              physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
              itemCount: _animals.length,
              itemBuilder: (context, index) {
                final animal = _animals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: textTheme.titleMedium
                              ?.copyWith(
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
            // --- End My Animals Section ---

            const SizedBox(height: 40), // Spacing before button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue, // Themed button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 18), // Larger button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // More rounded
                  ),
                  elevation: 8, // More prominent shadow
                  shadowColor: kPrimaryBlue.withOpacity(
                      0.4), // Themed shadow
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditPage(
                        profile: _profile!,
                        jwtToken: widget.jwtToken,
                      ),
                    ),
                  ).then(
                          (_) => _fetchProfileAndAnimals()); // Refresh profile AND animals after edit
                },
                child: Text(
                  'Edit Profile',
                  style: textTheme.labelLarge
                      ?.copyWith(fontSize: 18), // Use theme and adjust size
                ),
              ),
            ),

            // Inside your _ProfilePageState build method, within the main Column:

            const SizedBox(height: 20), // Add some spacing
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentBlue, // Use accent blue for this action
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16), // Slightly smaller than edit, but still prominent
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6, // Subtle shadow
                  shadowColor: kAccentBlue.withOpacity(0.4),
                ),
                onPressed: () {
                  // Ensure _profile and widget.jwtToken are not null before navigating
                  /*if (_profile != null && widget.jwtToken.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientResetPasswordPage(
                          email: _profile!.email, // Pass the user's email
                          token: widget.jwtToken, // Pass the JWT token
                        ),
                      ),
                    );
                  } else {
                    // Optionally show a snackbar if data is missing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile data or token not available for password reset.')),
                    );
                  }*/
                },
                child: Text(
                  'Change Password',
                  style: textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing after the button

          ],
        ),
      ),
    );
  }

  // Helper for contact info rows (email/phone)
  Widget _contactInfoRow(IconData icon, String value, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentBlue), // Accent blue icon
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

  // Helper for general info rows
  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
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
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding around each row
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kAccentBlue, size: 24), // Themed icon, slightly larger
          const SizedBox(width: 20), // Increased spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    // Use theme for label
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    // Use theme for value
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

  // Helper for animal detail rows within the animal card
  Widget _buildAnimalDetailRow(
      TextTheme textTheme, IconData icon, String label, String value) {
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

  // Custom themed divider
  Widget _themedDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0), // Spacing around divider
      child: Divider(
        height: 1, // Actual height of the line
        thickness: 0.8, // Thickness of the line
        color: kAccentBlue, // Themed color for the divider
      ),
    );
  }
}