import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';
import 'package:veterinary_app/services/consultation_services/consultation_service.dart';
import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veterinary_app/views/consultation_pages/add_consultation_page.dart';
import 'package:veterinary_app/views/consultation_pages/update_consultation_page.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/models/animal_models/animal_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';

// Assuming these imports for the new dialog functionality
import 'package:veterinary_app/services/auth_services/token_service.dart'; // For TokenService
import 'package:veterinary_app/views/animal_pages/animal_by_client_list_page.dart';
import '../chat_pages/ChatPage.dart'; // For ChatPage

// Import from your centralized color file.
import 'package:veterinary_app/utils/app_colors.dart';

class ConsultationListPage extends StatefulWidget {
  final String token;
  final String username;

  const ConsultationListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<ConsultationListPage> createState() => _ConsultationListPageState();
}

class _ConsultationListPageState extends State<ConsultationListPage> {
  late Future<List<Consultation>> _consultations;
  List<AnimalModel> _animals = [];
  bool _isLoadingAnimals = false;
  List<ClientModel> _clients = [];
  bool _isLoadingClients = false;

  // State variables for search and sort
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // false for newest to oldest (descending date), true for oldest to newest (ascending date)
  bool _isAscendingSort = false;

  @override
  void initState() {
    super.initState();
    _consultations = _fetchAndSortAndFilterConsultations(); // Initial fetch
    _fetchAnimals();
    _fetchClients();

    // Listen for changes in the search bar
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _consultations = _fetchAndSortAndFilterConsultations(); // Re-fetch with filter
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<List<Consultation>> _fetchAndSortAndFilterConsultations() async {
    List<Consultation> consultations =
    await ConsultationService.fetchConsultations(widget.token);

    // 1. Filter based on search query
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      consultations = consultations.where((consult) {
        // Search by client name, diagnostic, treatment, or notes
        return (consult.clientName?.toLowerCase().contains(queryLower) ?? false) ||
            (consult.diagnostic?.toLowerCase().contains(queryLower) ?? false) ||
            (consult.treatment?.toLowerCase().contains(queryLower) ?? false) ||
            (consult.notes?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    }

    // 2. Sort the list based on _isAscendingSort (old to new or new to old)
    if (_isAscendingSort) {
      consultations.sort((a, b) => a.date.compareTo(b.date)); // Oldest to newest (ascending date)
    } else {
      consultations.sort((a, b) => b.date.compareTo(a.date)); // Newest to oldest (descending date)
    }

    return consultations;
  }

  Future<void> _fetchAnimals() async {
    setState(() {
      _isLoadingAnimals = true;
    });
    try {
      final animals = await AnimalsVetService().getAnimalsList(widget.token);
      setState(() {
        _animals = animals;
      });
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Failed to load animals: $e', isSuccess: false);
      }
    } finally {
      setState(() {
        _isLoadingAnimals = false;
      });
    }
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoadingClients = true;
    });
    try {
      final clients = await ClientService().getAllClients(widget.token);
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Failed to load clients: $e', isSuccess: false);
      }
    } finally {
      setState(() {
        _isLoadingClients = false;
      });
    }
  }

  // Helper for showing snackbar messages
  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showAnimalDetails(String animalName) {
    final animal = _animals.firstWhere(
          (a) => a.name == animalName,
      orElse: () => AnimalModel(
        id: '',
        name: 'Unknown',
        espece: '',
        race: '',
        age: 0,
        sexe: '',
        allergies: '',
        anttecedentsmedicaux: '',
        ownerId: '',
      ),
    );

    if (animal.id == '') {
      if (context.mounted) {
        _showSnackBar('Animal details not found', isSuccess: false);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.pets, color: kPrimaryGreen), // Use kPrimaryGreen from app_colors.dart
              const SizedBox(width: 10),
              Text('Animal Details: ${animal.name}'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _buildDetailRow('Species:', animal.espece),
                _buildDetailRow('Breed:', animal.race),
                _buildDetailRow('Age:', animal.age.toString()),
                _buildDetailRow('Sex:', animal.sexe),
                _buildDetailRow('Allergies:',
                    animal.allergies.isNotEmpty ? animal.allergies : 'None'),
                _buildDetailRow(
                    'Medical History:',
                    animal.anttecedentsmedicaux.isNotEmpty
                        ? animal.anttecedentsmedicaux
                        : 'None'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showClientDetails(String clientName) {
    final client = _clients.firstWhere(
          (c) => c.username == clientName,
      orElse: () => ClientModel(
        id: '',
        username: 'Unknown',
        email: '',
        phoneNumber: '',
        address: '',
      ),
    );

    if (client.username == 'Unknown') {
      if (context.mounted) {
        _showSnackBar('Client details not found', isSuccess: false);
      }
      return;
    }

    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Consistent rounded corners
        ),
        backgroundColor: Theme.of(context).cardColor, // Themed background
        title: Row(
          children: [
            Icon(Icons.person, color: kPrimaryGreen), // Icon for client dialog
            const SizedBox(width: 10),
            Text(
              "Client: ${client.username}",
              style: textTheme.titleLarge?.copyWith(
                color: kPrimaryGreen, // Themed title color
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfoRow(
                textTheme, Icons.email_outlined, "Email", client.email),
            _buildClientInfoRow(
                textTheme, Icons.phone_outlined, "Phone", client.phoneNumber),
            _buildClientInfoRow(
                textTheme, Icons.home_outlined, "Address", client.address),
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
            label: Text("See Animals",
                style: textTheme.labelMedium?.copyWith(color: kAccentGreen)),
            onPressed: () {
              if (client.id.isEmpty || client.id == '0') {
                _showSnackBar('Invalid client ID', isSuccess: false);
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context); // Close the client details dialog
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
            icon: Icon(Icons.chat_bubble_outline_rounded,
                color: kPrimaryGreen), // Themed icon
            label: Text("Chat",
                style: textTheme.labelMedium?.copyWith(color: kPrimaryGreen)),
            onPressed: () async {
              Navigator.pop(context); // Close the client details dialog
              final token = await TokenService
                  .getToken(); // Assuming TokenService.getToken() exists
              if (token == null) {
                _showSnackBar('Authentication token not available. Please log in.',
                    isSuccess: false);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    // Assuming ChatPage exists
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
            child: Text("Cancel",
                style: textTheme.labelMedium?.copyWith(color: Colors.grey.shade700)),
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

  // Helper for consistent info rows in the client dialog
  Widget _buildClientInfoRow(
      TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  Future<void> _downloadDocument(String urlString) async {
    final Uri url = Uri.parse("${BaseUrl.api}/$urlString");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showSnackBar('Could not open document.', isSuccess: false);
      }
    }
  }

  void _showConsultationDetails(Consultation consult) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)), // Consistent rounded corners
          backgroundColor: Theme.of(context).cardColor, // Themed background
          title: Row(
            children: [
              Icon(Icons.medical_services,
                  color: kPrimaryGreen), // Themed icon
              const SizedBox(width: 10),
              Text(
                'Consultation Details',
                style: textTheme.titleLarge?.copyWith(
                  color: kPrimaryGreen, // Themed title color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _buildConsultationDetailRow(
                    textTheme, 'Client:', consult.clientName ?? 'N/A'),
                _buildConsultationDetailRow(
                    textTheme, 'Date:', formatDate(consult.date)),
                _buildConsultationDetailRow(
                    textTheme, 'Diagnostic:', consult.diagnostic ?? 'N/A'),
                _buildConsultationDetailRow(
                    textTheme, 'Treatment:', consult.treatment ?? 'N/A'),
                _buildConsultationDetailRow(
                    textTheme, 'Prescription:', consult.prescription ?? 'N/A'),
                _buildConsultationDetailRow(
                    textTheme, 'Notes:', consult.notes ?? 'N/A'),
                _buildConsultationDetailRow(
                  textTheme,
                  'Document:',
                  consult.documentPath != null && consult.documentPath!.isNotEmpty
                      ? consult.documentPath!.split('\\').last
                      : 'No Document',
                ),
                if (consult.documentPath != null && consult.documentPath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            final Uri uri = Uri.parse('${BaseUrl.api}/${consult.documentPath}');
                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                _showSnackBar('Could not open document in browser', isSuccess: false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showSnackBar('Error opening document: $e', isSuccess: false);
                            }
                          }
                        },
                        icon: const Icon(Icons.download_rounded, color: Colors.blue),
                        label: Text('View Document', style: textTheme.labelLarge?.copyWith(color: Colors.blue)),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: textTheme.labelLarge?.copyWith(color: Colors.grey.shade700)),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to build a consistent detail row in dialogs (used by both client and consultation details)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // New helper for consistent info rows in the consultation dialog, using TextTheme
  Widget _buildConsultationDetailRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label",
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge,
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
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Spacing between button and search bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search consultations (client, diagnostic, etc.)',
                      prefixIcon: Icon(Icons.search, color: kPrimaryGreen), // Themed icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Spacing between search bar and sort button
                // UPDATED: Sort Button with clearer icons
                IconButton(
                  icon: Icon(
                    // Show arrow down for newest first (descending), arrow up for oldest first (ascending)
                    _isAscendingSort ? Icons.arrow_upward : Icons.arrow_downward,
                    color: kPrimaryGreen,
                    size: 28,
                  ),
                  tooltip: _isAscendingSort ? 'Sort by Date (Oldest First)' : 'Sort by Date (Newest First)',
                  onPressed: () {
                    setState(() {
                      _isAscendingSort = !_isAscendingSort; // Toggle sort order
                      _consultations = _fetchAndSortAndFilterConsultations(); // Re-fetch/re-sort
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Consultation>>(
              future: _consultations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No consultations found. Add a new one!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final consult = snapshot.data![index];
                    return Card(
                      elevation: 4, // Add a subtle shadow
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8, // Increase vertical margin for better spacing
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Rounded corners for cards
                      ),
                      child: InkWell(
                        // Make the entire card tappable for details
                        onTap: () => _showConsultationDetails(consult),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Increase padding inside the card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    // Use Expanded to prevent overflow for long names
                                    child: Text(
                                      'Client: ${consult.clientName ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple, // Highlight client name
                                      ),
                                      overflow: TextOverflow.ellipsis, // Add ellipsis for long names
                                    ),
                                  ),
                                  const SizedBox(width: 10), // Spacing
                                  Text(
                                    formatDate(consult.date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 15, thickness: 1), // Separator
                              Text(
                                'Diagnostic: ${consult.diagnostic ?? 'N/A'}',
                                maxLines: 2, // Limit lines to prevent overflow
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Treatment: ${consult.treatment ?? 'N/A'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              _buildDocumentSection(
                                  consult), // Use a separate widget for document
                              const SizedBox(height: 10),
                              _buildActionButtons(
                                  context, consult), // Separate action buttons
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddConsultationPage(
                token: widget.token,
                username: widget.username,
              ),
            ),
          );

          if (result == true) {
            setState(() {
              _consultations = _fetchAndSortAndFilterConsultations(); // Refresh and re-sort
            });
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Consultation'),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Use theme color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Center the FAB
    );
  }

  // Helper method for document section
  Widget _buildDocumentSection(Consultation consult) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.description, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            consult.documentPath != null && consult.documentPath!.isNotEmpty
                ? consult.documentPath!.split('\\').last
                : 'No Document',
            overflow: TextOverflow.ellipsis,
            style: consult.documentPath != null && consult.documentPath!.isNotEmpty
                ? const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 15,
            )
                : const TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
        if (consult.documentPath != null && consult.documentPath!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.blue),
            tooltip: 'View Document',
            onPressed: () async {
              try {
                final Uri uri = Uri.parse('${BaseUrl.api}/${consult.documentPath}');
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  if (context.mounted) {
                    _showSnackBar('Could not open document in browser', isSuccess: false);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  _showSnackBar('Error opening document: $e', isSuccess: false);
                }
              }
            },
          ),
      ],
    );
  }

  // Helper method for action buttons
  Widget _buildActionButtons(BuildContext context, Consultation consult) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.person_outline, size: 20),
          label: const Text('Client'),
          onPressed: () => _showClientDetails(consult.clientName ?? ''),
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Edit'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateConsultationPage(
                  token: widget.token,
                  username: widget.username,
                  consultation: consult,
                ),
              ),
            ).then((value) {
              if (value == true) {
                setState(() {
                  _consultations = _fetchAndSortAndFilterConsultations();
                });
              }
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          icon: const Icon(Icons.info_outline, size: 20),
          label: const Text('More'),
          onPressed: () => _showConsultationDetails(consult),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}