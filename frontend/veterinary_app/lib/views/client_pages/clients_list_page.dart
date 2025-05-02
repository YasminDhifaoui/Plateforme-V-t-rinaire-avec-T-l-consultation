import 'package:flutter/material.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';

import '../components/home_navbar.dart';

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
                          title: Text(
                            client.username,
                          ), // Displaying the username
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email: ${client.email}',
                              ), // Displaying the email
                              SizedBox(height: 4), // Space between fields
                              Text(
                                'Phone: ${client.phoneNumber}',
                              ), // Displaying the phone number
                              SizedBox(height: 4), // Space between fields
                              Text(
                                'Address: ${client.address}',
                              ), // Displaying the address
                            ],
                          ),
                          trailing: Icon(
                            Icons.person,
                          ), // Optional icon at the end of the ListTile
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
