import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_services/token_service.dart';
import '../../services/vet_services/veterinaire_service.dart';
import '../../models/vet_models/veterinaire.dart';
import '../chat_pages/ChatPage.dart';
import '../rendezvous_pages/add_rendezvous_page.dart';
import '../components/home_navbar.dart';
import '../../utils/logout_helper.dart';

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
    username = widget.username;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? widget.username;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: username,
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
                    return GestureDetector(
                      onTap: () {
                        print("Selected Vet ID: ${vet.id}"); // <-- Add this line
                        _showVetOptionsDialog(context, vet);
                      },
                      child: Card(
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

  void _showVetOptionsDialog(BuildContext context, Veterinaire vet) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Contact ${vet.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: ${vet.email}"),
              Text("Phone: ${vet.phoneNumber}"),
              Text("Address: ${vet.address}"),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Send Message'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
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
                        receiverId: vet.id,
                        receiverUsername: vet.username, // ✅ Pass username here
                      ),
                    ),
                  );

                },
              ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddRendezvousPage(vet: vet),
                    ),
                  );
                },
                icon: Icon(Icons.calendar_today),
                label: Text('Make Appointment'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }
}
