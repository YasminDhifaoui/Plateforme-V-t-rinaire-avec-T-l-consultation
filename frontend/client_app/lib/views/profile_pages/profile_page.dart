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
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
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
    final primaryColor = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProfile, // Retry fetching the profile
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _profile == null
          ? const Center(child: Text('No profile data available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header: picture + username + email + phone
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/pet_owner.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profile!.userName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined,
                                      size: 18, color: primaryColor.withOpacity(0.8)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _profile!.email,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: primaryColor.withOpacity(0.85),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 18, color: primaryColor.withOpacity(0.8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _profile!.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: primaryColor.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoRow(Icons.person_outline, 'First Name', _profile!.firstName),
                    const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
                    _infoRow(Icons.person_outline, 'Last Name', _profile!.lastName),
                    const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
                    _infoRow(Icons.transgender, 'Gender', _profile!.gender),
                    const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
                    _infoRow(Icons.cake_outlined, 'Date of Birth', _profile!.birthDate),
                    const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
                    _infoRow(Icons.home_outlined, 'Address', _profile!.address),
                    const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
                    _infoRow(Icons.markunread_mailbox_outlined, 'Zip Code', _profile!.zipCode),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.5),
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
                  ).then((_) => _fetchProfile());
                },
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    value = value.isEmpty ? 'Not provided' : value;

    if (label == 'Date of Birth') {
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
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
