import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import '../../services/auth_services/token_service.dart';
import '../ChatPage.dart';
import '../components/home_navbar.dart';
import '../video_call_page.dart';

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.microphone.request();

  if (await Permission.camera.isGranted && await Permission.microphone.isGranted) {
    print("Permissions granted");
  } else {
    print("Permissions denied");
  }
}

class ClientsListPage extends StatefulWidget {
  final String token;
  final String username;

  const ClientsListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  final ClientService _clientService = ClientService();
  late Future<List<ClientModel>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = _clientService.getAllClients(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ClientModel>>(
              future: _clientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No clients found.'));
                } else {
                  final clients = snapshot.data!;
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(client.username),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${client.email}'),
                              const SizedBox(height: 4),
                              Text('Phone: ${client.phoneNumber}'),
                              const SizedBox(height: 4),
                              Text('Address: ${client.address}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat, color: Colors.blue),
                                tooltip: 'Chat',
                                onPressed: () async {
                                  final token = await TokenService.getToken();
                                  if (token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Token not available')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        token: token,
                                        receiverId: client.id.toString(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.video_call, color: Colors.green),
                                tooltip: 'Video Call',
                                onPressed: () async {
                                  await _requestPermissions();

                                  final token = await TokenService.getToken();
                                  if (token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Token not available')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoCallPageVet(
                                        jwtToken: token,
                                        peerId: client.id.toString(),
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
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
