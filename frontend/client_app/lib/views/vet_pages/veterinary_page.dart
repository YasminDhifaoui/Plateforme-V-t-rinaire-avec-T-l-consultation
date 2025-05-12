import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_services/token_service.dart';
import '../../services/vet_services/veterinaire_service.dart';
import '../../models/vet_models/veterinaire.dart';
import '../components/home_navbar.dart';
import '../../utils/logout_helper.dart';
import 'package:permission_handler/permission_handler.dart';

import '../video_call_page.dart';

Future<void> _requestPermissions() async {
  // Request camera and microphone permissions
  await Permission.camera.request();
  await Permission.microphone.request();

  // Check if all permissions are granted
  if (await Permission.camera.isGranted && await Permission.microphone.isGranted) {
    print("Permissions granted");
  } else {
    print("Permissions denied");
  }
}

class VetListPage extends StatefulWidget {
  const VetListPage({Key? key}) : super(key: key);

  @override
  State<VetListPage> createState() => _VetListPageState();
}

class _VetListPageState extends State<VetListPage> {
  final VeterinaireService vetService = VeterinaireService();
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
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
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Back to Home',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Veterinaire>>(
              future: vetService.getAllVeterinaires(),  // Use the VeterinaireService here
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
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vet.email,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vet.phoneNumber,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vet.address,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.video_call, color: Colors.green),
                          tooltip: 'Start Video Call',
                          onPressed: () async {
                            // Request camera/mic permissions
                            await _requestPermissions();

                            final token = await TokenService.getToken();
                            final userId = await TokenService.getUserId();

                            if (token == null || userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User info missing')),
                              );
                              return;
                            }


                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPage(
                                  jwtToken: token,
                                  userId: userId,
                                  peerId: vet.id.toString(),  // vet.id must exist and be a string or converted to string
                                ),
                              ),
                            );
                          },
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
}