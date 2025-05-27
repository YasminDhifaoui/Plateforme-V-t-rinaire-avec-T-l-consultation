import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/rendezvous_models/rendezvous_model.dart';
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart';
import '../components/home_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class RendezVousListPage extends StatefulWidget {
  final String token;
  final String username;

  const RendezVousListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<RendezVousListPage> createState() => _RendezVousListPageState();
}

class _RendezVousListPageState extends State<RendezVousListPage> {
  late Future<List<RendezVousModel>> _rdvFuture;
  final RendezVousService _service = RendezVousService();

  @override
  void initState() {
    super.initState();
    // Call the method to fetch and sort the appointments
    _rdvFuture = _fetchAndSortRendezVous();
  }

  // Method to fetch and sort rendezvous
  Future<List<RendezVousModel>> _fetchAndSortRendezVous() async {
    final rendezVousList = await _service.getRendezVousList(widget.token);
    // Sort from newest to oldest date
    rendezVousList.sort((a, b) {
      try {
        final DateTime dateA = DateTime.parse(a.date);
        final DateTime dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        // Handle cases where date string might be invalid or unparseable
        debugPrint('Error parsing date for sorting: $e');
        return 0; // Don't change order if dates are invalid
      }
    });
    return rendezVousList;
  }

  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
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

  Widget getStatusWidget(String status) {
    int statusValue = int.tryParse(status) ?? -1;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (statusValue) {
      case 0:
        statusText = 'Confirmed';
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 1:
        statusText = 'Canceled';
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      case 2:
        statusText = 'Completed'; // Changed to 'Completed' for professional tone
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.task_alt_rounded;
        break;
      default:
        statusText = 'Unknown';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void showEditStatusDialog(RendezVousModel rdv) {
    int selectedStatus = int.tryParse(rdv.status) ?? 0;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Change Status for ${rdv.clientName}',
            style: textTheme.titleLarge?.copyWith(color: kPrimaryGreen),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Date: ${formatDate(rdv.date)}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select New Status:',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kAccentGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Confirmed')),
                      DropdownMenuItem(value: 1, child: Text('Canceled')),
                      DropdownMenuItem(value: 2, child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                    style: textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.updateRendezVousStatus(
                    widget.token,
                    rdv.id,
                    selectedStatus,
                  );
                  Navigator.of(context).pop();
                  _showSnackBar('Status updated successfully!', isSuccess: true);
                  setState(() {
                    // Re-fetch and re-sort the list after an update
                    _rdvFuture = _fetchAndSortRendezVous();
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar('Failed to update status: $e', isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
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
      body: FutureBuilder<List<RendezVousModel>>(
        future: _rdvFuture,
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
                      'Failed to load appointments: ${snapshot.error}',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchAndSortRendezVous, // Retry button
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
                    Icons.event_note_rounded, // Engaging icon for no appointments
                    color: kAccentGreen,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No appointments found!',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedule a new one to see it here.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            final rdvs = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0), // Consistent padding
              itemCount: rdvs.length,
              itemBuilder: (context, index) {
                final rdv = rdvs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8, // Adjusted horizontal margin
                    vertical: 8, // Adjusted vertical margin
                  ),
                  elevation: 8, // More pronounced shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18), // More rounded corners
                  ),
                  child: InkWell( // Added InkWell for tap feedback
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showEditStatusDialog(rdv), // Tap card to edit status
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Increased padding inside card
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: kPrimaryGreen, size: 24), // Icon for date
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Date: ${formatDate(rdv.date)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryGreen, // Themed title color
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 0.8, color: Colors.grey), // Themed divider
                          _buildRendezvousInfoRow(textTheme, Icons.person_rounded, 'Client', rdv.clientName),
                          _buildRendezvousInfoRow(textTheme, Icons.pets_rounded, 'Animal', rdv.animalName),
                          const SizedBox(height: 10), // Spacing before status
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: kAccentGreen, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Status: ',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              getStatusWidget(rdv.status),
                            ],
                          ),
                          const SizedBox(height: 16), // Spacing before button
                          Center( // Center the button
                            child: ElevatedButton.icon(
                              onPressed: () => showEditStatusDialog(rdv),
                              icon: const Icon(Icons.edit_rounded, color: Colors.white), // Edit icon
                              label: Text('Edit Status', style: textTheme.labelLarge), // Themed label
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentGreen, // Use accent green for actions
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
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

  // Helper widget to build consistent info rows
  Widget _buildRendezvousInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Adjusted vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccentGreen), // Themed icon
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
              value,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow text to wrap if long
            ),
          ),
        ],
      ),
    );
  }
}