import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/profile_models/profile_model.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/profile_services/profile_service.dart';
import 'package:veterinary_app/views/profile_pages/profile_edit_page.dart';

class VetProfilePage extends StatefulWidget {
  const VetProfilePage({super.key});

  @override
  State<VetProfilePage> createState() => _VetProfilePageState();
}

class _VetProfilePageState extends State<VetProfilePage> {
  ProfileModel? _vetProfile;
  bool isLoading = true;
  String errorMessage = '';
  String? jwtToken;

  late ProfileService vetProfileService;

  @override
  void initState() {
    super.initState();
    vetProfileService = ProfileService(
      profileUrl: "http://10.0.2.2:5000/api/veterinaire/profile/see-profile",
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      jwtToken = await TokenService.getToken();
      if (jwtToken != null) {
        final profile = await vetProfileService.fetchProfile(jwtToken!);
        setState(() {
          _vetProfile = profile;
          isLoading = false;
        });
      } else {
        throw Exception('Token not found');
      }
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
        backgroundColor: Colors.green,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_vetProfile != null)
                    Text(
                      _vetProfile!.userName,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/doctor.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _vetProfile == null
              ? const Center(child: Text('No profile data found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Veterinarian Information',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _infoRow(Icons.person, 'Name', _vetProfile!.userName),
                        _infoRow(Icons.email, 'Email', _vetProfile!.email),
                        _infoRow(
                          Icons.phone,
                          'Phone Number',
                          _vetProfile!.phoneNumber,
                        ),
                        _infoRow(
                          Icons.account_circle,
                          'First Name',
                          _vetProfile!.firstName,
                        ),
                        const SizedBox(height: 16),
                        _infoRow(
                          Icons.account_circle_outlined,
                          'Last Name',
                          _vetProfile!.lastName,
                        ),
                        const SizedBox(height: 16),
                        _infoRow(
                          Icons.cake,
                          'Birth Date',
                          formatDate(_vetProfile!.birthDate),
                        ),
                        const SizedBox(height: 16),
                        _infoRow(Icons.home, 'Address', _vetProfile!.address),
                        const SizedBox(height: 16),
                        _infoRow(
                          Icons.location_pin,
                          'Zip Code',
                          _vetProfile!.zipCode,
                        ),
                        const SizedBox(height: 16),
                        _infoRow(Icons.wc, 'Gender', _vetProfile!.gender),
                      ],
                    ),
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProfileEditPage(
                    profile: _vetProfile!,
                    jwtToken: jwtToken!,
                  ),
            ),
          ).then((_) => _initialize());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    value = value.isEmpty ? 'Not provided' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }
}
