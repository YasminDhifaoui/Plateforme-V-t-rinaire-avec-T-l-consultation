import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_services/token_service.dart';
import '../../services/vet_services/veterinaire_service.dart';
import '../../models/vet_models/veterinaire.dart';
import '../../utils/app_colors.dart';
import '../chat_pages/ChatPage.dart';
import '../rendezvous_pages/add_rendezvous_page.dart';

// Import your blue color constants
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

class VetListPage extends StatefulWidget {
  final String username;

  const VetListPage({Key? key, required this.username}) : super(key: key);

  @override
  State<VetListPage> createState() => _VetListPageState();
}

class _VetListPageState extends State<VetListPage> {
  final VeterinaireService vetService = VeterinaireService();
  String _username = '';
  List<Veterinaire> _allVets = []; // Stores the full list of vets
  List<Veterinaire> _filteredVets = []; // Stores the currently filtered list
  final TextEditingController _searchController = TextEditingController(); // Controller for search input
  late Future<List<Veterinaire>> _initialVetsFuture; // Future to handle initial fetching

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadUserData();
    _initialVetsFuture = _fetchInitialVets(); // Start fetching vets immediately

    // Add listener to the search controller to filter vets as user types
    _searchController.addListener(_filterVets);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterVets);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('username')) {
      setState(() {
        _username = prefs.getString('username') ?? widget.username;
      });
    }
  }

  Future<List<Veterinaire>> _fetchInitialVets() async {
    try {
      final vets = await vetService.getAllVeterinaires();
      setState(() {
        _allVets = vets;
        _filteredVets = vets; // Initialize filtered list with all vets
      });
      return vets; // Return for the FutureBuilder
    } catch (e) {
      _showSnackBar("Failed to load veterinarians. Please try again.", isSuccess: false);
      rethrow; // Rethrow to let FutureBuilder catch the error
    }
  }

  void _filterVets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVets = _allVets.where((vet) {
        return vet.username.toLowerCase().contains(query) ||
            vet.email.toLowerCase().contains(query) ||
            vet.address.toLowerCase().contains(query) ||
            vet.phoneNumber.toLowerCase().contains(query);
      }).toList();
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
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kLightGreyBackground, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Find a Veterinarian', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vets by name, email, or address...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                prefixIcon: Icon(Icons.search, color: kPrimaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    _filterVets(); // Clear filter
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              ),
              style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
              cursorColor: kPrimaryBlue,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Veterinaire>>(
              future: _initialVetsFuture, // Use the future initialized in initState
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            "Failed to load veterinarians: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Trigger re-fetch of initial vets
                              setState(() {
                                _initialVetsFuture = _fetchInitialVets();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Retry', style: textTheme.labelLarge),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_allVets.isEmpty) { // No vets found at all after successful fetch
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_rounded, color: Colors.grey.shade400, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          "No veterinarians found at the moment.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Trigger re-fetch of initial vets
                            setState(() {
                              _initialVetsFuture = _fetchInitialVets();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Refresh', style: textTheme.labelLarge),
                        ),
                      ],
                    ),
                  );
                } else if (_filteredVets.isEmpty && _searchController.text.isNotEmpty) {
                  // No vets matching search query
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 80), // No search results icon
                        const SizedBox(height: 16),
                        Text(
                          "No veterinarians match your search.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Try a different name or location.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                }


                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  itemCount: _filteredVets.length,
                  itemBuilder: (context, index) {
                    final vet = _filteredVets[index]; // Use filtered list
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          print("Selected Vet ID: ${vet.id}");
                          _showVetOptionsDialog(context, vet);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kAccentBlue, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/veterinary.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vet.username,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: kPrimaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(Icons.email_outlined, vet.email, textTheme),
                                    const SizedBox(height: 2),
                                    _buildInfoRow(Icons.phone_outlined, vet.phoneNumber, textTheme),
                                    const SizedBox(height: 2),
                                    _buildInfoRow(Icons.location_on_outlined, vet.address, textTheme),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: kAccentBlue,
                                size: 24,
                              ),
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

  Widget _buildInfoRow(IconData icon, String text, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kAccentBlue.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Not provided' : text,
            style: textTheme.bodySmall?.copyWith(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showVetOptionsDialog(BuildContext context, Veterinaire vet) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_hospital_rounded,
                  color: kPrimaryBlue,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  vet.username,
                  style: textTheme.headlineSmall?.copyWith(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Contact Information:',
                  style: textTheme.titleMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.email_outlined, vet.email, textTheme),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.phone_outlined, vet.phoneNumber, textTheme),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.location_on_outlined, vet.address, textTheme),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message_rounded),
                    label: Text('Send Message', style: textTheme.labelLarge),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final token = await TokenService.getToken();
                      if (token == null) {
                        _showSnackBar('Authentication token missing.', isSuccess: false);
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            token: token,
                            receiverId: vet.id,
                            receiverUsername: vet.username,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  // The button in your dialog that navigates to AddRendezvousPage

                  child: ElevatedButton.icon(
                    onPressed: () async { // <-- Make the onPressed an 'async' function
                      Navigator.pop(dialogContext); // Close the current dialog first

                      // Await the result from AddRendezvousPage
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRendezvousPage(vet: vet),
                        ),
                      );

                      // Check if the result indicates success (e.g., if 'true' was returned)
                      if (result == true) {
                        // Assuming this code is in your RendezvousListPage's State or a parent that manages it.
                        // You need to call the method that refreshes your appointments list.
                        // This typically involves setting the state of the FutureBuilder's future.

                        _showSnackBar('Appointments list refreshing...', isSuccess: true); // User feedback


                      }
                    },
                    icon: Icon(Icons.calendar_today_rounded),
                    label: Text('Make Appointment', style: textTheme.labelLarge),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  child: Text('Close', style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue)),
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}