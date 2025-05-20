import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/profile_models/profile_model.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/profile_services/profile_service.dart';
import 'package:veterinary_app/utils/base_url.dart';
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

  late final ProfileService vetProfileService;

  final Color primaryGreen = const Color(0xFF2e7d32);
  final Color accentGreen = const Color(0xFF81c784);
  final Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    vetProfileService = ProfileService(
      profileUrl: "${BaseUrl.api}/api/veterinaire/profile/see-profile",
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      jwtToken = await TokenService.getToken();
      if (jwtToken == null) throw Exception('Authentication token missing');

      final profile = await vetProfileService.fetchProfile(jwtToken!);

      setState(() {
        _vetProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading profile: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: primaryGreen,
        elevation: 2,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _vetProfile == null
              ? const Center(
                child: Text(
                  'No profile data available.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
              : _buildProfileContent(),
      bottomNavigationBar:
          _vetProfile != null
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (jwtToken != null && _vetProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfileEditPage(
                                profile: _vetProfile!,
                                jwtToken: jwtToken!,
                              ),
                        ),
                      ).then((_) => _loadProfile());
                    }
                  },
                ),
              )
              : null,
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: const AssetImage('assets/images/doctor.png'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vetProfile!.userName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: primaryGreen.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _vetProfile!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryGreen.withOpacity(0.7),
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: primaryGreen.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _vetProfile!.phoneNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryGreen.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(
              Icons.person_outline,
              'First Name',
              _vetProfile!.firstName,
            ),
            const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
            _infoRow(Icons.person_outline, 'Last Name', _vetProfile!.lastName),
            const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
            _infoRow(
              Icons.cake_outlined,
              'Date of Birth',
              _formatDate(_vetProfile!.birthDate),
            ),
            const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
            _infoRow(Icons.home_outlined, 'Address', _vetProfile!.address),
            const Divider(height: 32, thickness: 1, color: Color(0xffe0e0e0)),
            _infoRow(
              Icons.markunread_mailbox_outlined,
              'Zip Code',
              _vetProfile!.zipCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }
}
