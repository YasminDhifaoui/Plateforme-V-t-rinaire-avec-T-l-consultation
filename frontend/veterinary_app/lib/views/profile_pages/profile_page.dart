import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/profile_models/profile_model.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/profile_services/profile_service.dart';
import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/views/profile_pages/profile_edit_page.dart';
// Import the VetResetPasswordPage
import 'package:veterinary_app/views/Auth_pages/vet_reset_password_page.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: AppBar(
        // AppBar styling is handled by AppBarTheme in main.dart
        title: Text(
          'My Profile',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
            color: kPrimaryGreen), // Themed loading indicator
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                style: textTheme.bodyLarge
                    ?.copyWith(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile, // Retry fetching the profile
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen, // Themed button
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
          : _vetProfile == null
          ? Center(
        child: Text(
          'No profile data available.',
          style: textTheme.bodyLarge
              ?.copyWith(color: Colors.black54),
        ),
      )
          : _buildProfileContent(textTheme), // Pass textTheme
      bottomNavigationBar: _vetProfile != null
          ? Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min size for column
          children: [
            // Edit Profile Button
            ElevatedButton.icon(
              onPressed: () {
                if (jwtToken != null && _vetProfile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEditPage(
                        profile: _vetProfile!,
                        jwtToken: jwtToken!,
                      ),
                    ),
                  ).then((_) => _loadProfile()); // Refresh profile after edit
                }
              },
              // --- Styled Button ---
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen, // Use primary green for background
                foregroundColor: Colors.white, // White text and icon
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Generous padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                elevation: 6, // More pronounced shadow
                shadowColor: kPrimaryGreen.withOpacity(0.4), // Themed shadow color
              ),
              // --- End Styled Button ---
              icon: const Icon(Icons.edit_rounded,
                  color: Colors.white), // Modern edit icon
              label: Text(
                'Edit Profile',
                style: textTheme.labelLarge, // Use themed labelLarge
              ),
            ),
            const SizedBox(height: 12), // Spacing between buttons
            // Reset Password Button
            ElevatedButton.icon(
              onPressed: () {
                if (_vetProfile != null && _vetProfile!.email.isNotEmpty) {
                  // In a real app, 'token' would be generated by your backend
                  // and securely provided, not a hardcoded string.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VetResetPasswordPage(
                        email: _vetProfile!.email,
                        token: "your_actual_reset_token_from_backend", // <<< IMPORTANT: REPLACE THIS!
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Email not available for password reset.',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                }
              },
              // --- Styled Button ---
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentGreen, // Use accent green for a slight distinction
                foregroundColor: Colors.white, // White text and icon
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Generous padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                elevation: 6, // More pronounced shadow
                shadowColor: kAccentGreen.withOpacity(0.4), // Themed shadow color
              ),
              // --- End Styled Button ---
              icon: const Icon(Icons.vpn_key_rounded,
                  color: Colors.white), // Key icon for password reset
              label: Text(
                'Reset Password', // Clearer text
                style: textTheme.labelLarge,
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildProfileContent(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          _buildProfileHeader(textTheme), // Pass textTheme
          const SizedBox(height: 32),
          _buildInfoCard(textTheme), // Pass textTheme
        ],
      ),
    );
  }

  Widget _buildProfileHeader(TextTheme textTheme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kPrimaryGreen.withOpacity(0.15), // Themed shadow color
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: const AssetImage('assets/images/doctor.png'), // Ensure this asset exists
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback if image fails to load
              print('Error loading doctor.png: $exception');
            },
            child: _vetProfile!.userName.isEmpty // Fallback for no image
                ? Icon(Icons.person_rounded, size: 60, color: Colors.grey.shade400)
                : null,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vetProfile!.userName,
                style: textTheme.headlineSmall?.copyWith(
                  // Use themed headlineSmall
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen, // Themed username color
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: kAccentGreen, // Themed icon color
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _vetProfile!.email,
                      style: textTheme.bodyMedium?.copyWith(
                        // Use themed bodyMedium
                        color: Colors.black87, // Themed text color
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
                    color: kAccentGreen, // Themed icon color
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _vetProfile!.phoneNumber,
                    style: textTheme.bodyMedium?.copyWith(
                      // Use themed bodyMedium
                      color: Colors.black87, // Themed text color
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

  Widget _buildInfoCard(TextTheme textTheme) {
    return Card(
      // Card styling is handled by CardThemeData in main.dart
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Details',
              style: textTheme.titleLarge?.copyWith(
                // Use themed titleLarge
                fontWeight: FontWeight.w700,
                color: kPrimaryGreen, // Themed section title color
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(
              textTheme, // Pass textTheme
              Icons.person_outline_rounded, // Modern icon
              'First Name',
              _vetProfile!.firstName,
            ),
            _themedDivider(), // Use custom themed divider
            _infoRow(textTheme, Icons.person_outline_rounded, 'Last Name',
                _vetProfile!.lastName),
            _themedDivider(),
            _infoRow(
              textTheme, // Pass textTheme
              Icons.cake_outlined,
              'Date of Birth',
              _formatDate(_vetProfile!.birthDate),
            ),
            _themedDivider(),
            _infoRow(textTheme, Icons.home_outlined, 'Address',
                _vetProfile!.address),
            _themedDivider(),
            _infoRow(
              textTheme, // Pass textTheme
              Icons.markunread_mailbox_outlined,
              'Zip Code',
              _vetProfile!.zipCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentGreen), // Themed icon color
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              // Use themed titleMedium
              color: kPrimaryGreen, // Themed label color
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: textTheme.bodyLarge?.copyWith(color: Colors.black87), // Themed value text
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(date); // Changed format for better readability
    } catch (_) {
      return 'Invalid date';
    }
  }

  // Custom themed divider (defined locally for this file, but could be global)
  Widget _themedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Increased vertical padding
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: kAccentGreen.withOpacity(0.5), // Lighter themed color for divider
      ),
    );
  }
}