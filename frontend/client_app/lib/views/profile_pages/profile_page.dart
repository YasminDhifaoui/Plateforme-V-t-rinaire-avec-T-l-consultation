import 'package:client_app/models/profile_models/profile_model.dart';
import 'package:client_app/views/profile_pages/profile_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/services/profile_services/profile_service.dart';
import 'package:intl/intl.dart'; // Import intl package

class ProfilePage extends StatefulWidget {
  final String jwtToken;

  const ProfilePage({Key? key, required this.jwtToken}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileModel? _profile;
  bool isLoading = true;
  String errorMessage = '';

  late ProfileService profileService;

  @override
  void initState() {
    super.initState();
    profileService = ProfileService(
      profileUrl: "http://10.0.2.2:5000/api/client/profile/see-profile",
    );
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profileData = await profileService.fetchProfile(widget.jwtToken);
      setState(() {
        _profile = profileData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile: $e';
        isLoading = false;
      });
    }
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
        title: const Text(''),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_profile != null)
                    Text(
                      _profile!.userName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Optionally handle profile picture tap if needed
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/pet_owner.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _fetchProfile, // Retry fetching the profile
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('No profile data available'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.teal.shade50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[800],
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    _infoRow(
                                        Icons.email, 'Email', _profile!.email),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.person, 'Username',
                                        _profile!.userName),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.phone, 'Phone Number',
                                        _profile!.phoneNumber),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.account_circle, 'First Name',
                                        _profile!.firstName),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.account_circle_outlined,
                                        'Last Name', _profile!.lastName),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.cake, 'Birth Date',
                                        _profile!.birthDate),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.home, 'Address',
                                        _profile!.address),
                                    const SizedBox(height: 16),
                                    _infoRow(Icons.location_pin, 'Zip Code',
                                        _profile!.zipCode),
                                    const SizedBox(height: 16),
                                    _infoRow(
                                        Icons.wc, 'Gender', _profile!.gender),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Animals:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.teal[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: _profile!.animalNames
                                          .map(
                                            (name) => InkWell(
                                              onTap: () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Animal: $name')),
                                                );
                                              },
                                              child: Chip(
                                                label: Text(
                                                  name,
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                                backgroundColor:
                                                    Colors.teal.shade100,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileEditPage(
                                        profile:
                                            _profile!, // send the current profile
                                        jwtToken: widget.jwtToken,
                                      ),
                                    ),
                                  ).then((_) {
                                    // After editing, refresh the profile
                                    _fetchProfile();
                                  });
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    // Check if the value is null or empty
    value = value.isEmpty ? 'Not provided' : value;

    // Format the birth date if the label is "Birth Date"
    if (label == 'Birth Date') {
      try {
        DateTime birthDate = DateTime.parse(value);
        value = DateFormat('dd/MM/yyyy').format(birthDate);
      } catch (e) {
        value = 'Invalid date';
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
