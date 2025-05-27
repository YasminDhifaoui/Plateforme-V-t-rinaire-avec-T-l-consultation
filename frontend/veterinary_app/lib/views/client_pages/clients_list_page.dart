import 'package:flutter/material.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import '../../services/auth_services/token_service.dart';
import '../chat_pages/ChatPage.dart';
import '../animal_pages/animal_by_client_list_page.dart';
import '../components/home_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

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

  // Method to refresh the client list
  void _refreshClientsList() {
    setState(() {
      _clientsFuture = _clientService.getAllClients(widget.token);
    });
  }

  // Helper to show themed SnackBar feedback
  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: isSuccess ? kPrimaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showClientDialog(ClientModel client) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Consistent rounded corners
        ),
        backgroundColor: Theme.of(context).cardTheme.color, // Themed background
        title: Text(
          "Client: ${client.username}",
          style: textTheme.titleLarge?.copyWith(
            color: kPrimaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfoRow(textTheme, Icons.email_outlined, "Email", client.email),
            _buildClientInfoRow(textTheme, Icons.phone_outlined, "Phone", client.phoneNumber),
            _buildClientInfoRow(textTheme, Icons.home_outlined, "Address", client.address),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 10),
            Text(
              "Actions",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kPrimaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          // See Animals Button
          TextButton.icon(
            icon: Icon(Icons.pets_rounded, color: kAccentGreen), // Themed icon
            label: Text("See Animals", style: textTheme.labelMedium?.copyWith(color: kAccentGreen)),
            onPressed: () {
              if (client.id.isEmpty || client.id == '0') {
                _showSnackBar('Invalid client ID', isSuccess: false);
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalByClientListPage(
                    clientId: client.id,
                    token: widget.token,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          // Chat Button
          TextButton.icon(
            icon: Icon(Icons.chat_bubble_outline_rounded, color: kPrimaryGreen), // Themed icon
            label: Text("Chat", style: textTheme.labelMedium?.copyWith(color: kPrimaryGreen)),
            onPressed: () async {
              Navigator.pop(context);
              final token = await TokenService.getToken();
              if (token == null) {
                _showSnackBar('Authentication token not available. Please log in.', isSuccess: false);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    token: token,
                    receiverId: client.id,
                    receiverUsername: client.username,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          // Cancel Button
          TextButton(
            child: Text("Cancel", style: textTheme.labelMedium?.copyWith(color: Colors.grey.shade700)),
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent client info rows in dialog
  Widget _buildClientInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccentGreen),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value, // Handle empty values gracefully
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: FutureBuilder<List<ClientModel>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kPrimaryGreen), // Themed loading indicator
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded, // Error icon
                      color: Colors.red.shade400,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load clients: ${snapshot.error}',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshClientsList, // Retry button
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: Text('Retry', style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_alt_rounded, // Engaging icon for no clients
                    color: kAccentGreen,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No clients found!',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your client list will appear here.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            final clients = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0), // Consistent padding
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Adjusted margin
                  elevation: 8, // More pronounced shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18), // More rounded corners
                  ),
                  child: InkWell( // Added InkWell for tap feedback
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showClientDialog(client),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Increased padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24, // Consistent avatar size
                                backgroundColor: kPrimaryGreen, // Themed avatar background
                                child: Text(
                                  client.username.isNotEmpty
                                      ? client.username[0].toUpperCase()
                                      : '?',
                                  style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  client.username,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryGreen,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: kAccentGreen, size: 20), // Trailing icon
                            ],
                          ),
                          const Divider(height: 25, thickness: 0.8, color: Colors.grey), // Themed divider
                          _buildClientInfoRow(textTheme, Icons.email_outlined, "Email", client.email),
                          _buildClientInfoRow(textTheme, Icons.phone_outlined, "Phone", client.phoneNumber),
                          _buildClientInfoRow(textTheme, Icons.home_outlined, "Address", client.address),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      // --- Floating Action Button (Return Button) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context); // Navigates back to the previous page
        },
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), // Modern back icon
        label: Text('Return', style: Theme.of(context).textTheme.labelLarge), // Themed label style
        backgroundColor: kPrimaryGreen, // Themed background color
        foregroundColor: Colors.white, // White icon and text
        elevation: 6, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded shape
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Center the FAB
    );
  }
}

// NOTE: The `SeeAnimalsPage` widget is a StatelessWidget and was not requested for styling.
// If you intend to use it, you should style it separately to match the theme.
class SeeAnimalsPage extends StatelessWidget {
  final String clientId;
  final String clientUsername;

  const SeeAnimalsPage({
    super.key,
    required this.clientId,
    required this.clientUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$clientUsername\'s Animals')),
      body: Center(
        child: Text(
          'List of animals for $clientUsername (ID: $clientId)',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}