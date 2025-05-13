import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_services/token_service.dart';
import '../../services/vet_services/veterinaire_service.dart';
import '../../models/vet_models/veterinaire.dart';
import '../telecommunication_pages/ChatPage.dart';
import '../components/home_navbar.dart';
import '../../utils/logout_helper.dart';
import '../telecommunication_pages/video_call_page.dart';

class VetListPage extends StatefulWidget {
  final String username;

  const VetListPage({Key? key, required this.username}) : super(key: key);

  @override
  State<VetListPage> createState() => _VetListPageState();
}

class _VetListPageState extends State<VetListPage> {
  final VeterinaireService vetService = VeterinaireService();
  late String username;

  @override
  void initState() {
    super.initState();
    username = widget.username; // Initialize with the passed username
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? widget.username; // Fallback to widget.username
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: username, // Use the username from the state
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back to Home',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Veterinaire>>(
              future: vetService.getAllVeterinaires(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No veterinaires found."));
                }

                final vets = snapshot.data!;
                return ListView.builder(
                  itemCount: vets.length,
                  itemBuilder: (context, index) {
                    final vet = vets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: const CircleAvatar(
                          backgroundImage: AssetImage('assets/images/veterinary.png'),
                          radius: 24,
                        ),
                        title: Text(
                          vet.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.email, vet.email),
                            const SizedBox(height: 4),
                            _buildInfoRow(Icons.phone, vet.phoneNumber),
                            const SizedBox(height: 4),
                            _buildInfoRow(Icons.location_on, vet.address),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.blue),
                              tooltip: 'Send Message',
                              onPressed: () async {
                                final token = await TokenService.getToken();

                                if (token == null) {
                                  _showSnackBar(context, 'Token missing');
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      token: token,
                                      receiverId: vet.id.toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.video_call, color: Colors.green),
                              tooltip: 'Start Video Call',
                              onPressed: () async {
                                await _requestPermissions();

                                final token = await TokenService.getToken();
                                final userId = await TokenService.getUserId();

                                if (token == null || userId == null) {
                                  _showSnackBar(context, 'User info missing');
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoCallPageClient(
                                      jwtToken: token,
                                      peerId: vet.id.toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
