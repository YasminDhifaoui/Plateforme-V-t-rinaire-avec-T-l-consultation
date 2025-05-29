import 'package:client_app/services/rendezvous_services/rendezvous_service.dart';
import 'package:client_app/views/rendezvous_pages/update_rendezvous_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_app/models/rendezvous_models/rendezvous.dart';
import 'package:client_app/services/rendezvous_services/delete_rendezvous.dart';
// import 'package:client_app/views/components/home_navbar.dart'; // Replaced with standard AppBar
// import 'package:client_app/utils/logout_helper.dart'; // Keep if used for general logout logic

import '../vet_pages/veterinary_page.dart';

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart'; // Adjust path if using a separate constants.dart

enum RendezvousSortOrder {
  dateDesc, // Newest first
  dateAsc, // Oldest first
  vetAsc, // By Vet Name (A-Z)
  animalAsc, // By Animal Name (A-Z)
}

class RendezvousPage extends StatefulWidget {
  final String username;

  const RendezvousPage({Key? key, required this.username}) : super(key: key);

  @override
  State<RendezvousPage> createState() => _RendezvousPageState();
}

class _RendezvousPageState extends State<RendezvousPage> {
  late Future<List<Rendezvous>> _rendezvousFuture;
  final RendezvousService _rendezvousService = RendezvousService(); // Use instance
  final DeleteRendezvousService _deleteRendezvousService = DeleteRendezvousService(); // Use instance

  List<Rendezvous> _allRendezvous = []; // Stores the unfiltered list
  List<Rendezvous> _filteredRendezvousList = []; // Stores filtered/sorted list

  final TextEditingController _searchController = TextEditingController();
  RendezvousSortOrder _currentSortOrder = RendezvousSortOrder.dateDesc;


  @override
  void initState() {
    super.initState();
    _rendezvousFuture = _fetchRendezvous();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Rendezvous>> _fetchRendezvous() async {
    try {
      final rendezvousList = await _rendezvousService.getRendezvousList();
      setState(() {
        _allRendezvous = rendezvousList; // Update the allRendezvous list
        _applyFiltersAndSort(); // Apply filters and sort immediately after fetching
      });
      return rendezvousList; // Return the raw list for the FutureBuilder
    } catch (e) {
      _showSnackBar('Failed to load appointments: $e', isSuccess: false);
      rethrow; // Re-throw to let FutureBuilder handle the error state
    }
  }

  void _applyFiltersAndSort() {
    String query = _searchController.text.toLowerCase();
    List<Rendezvous> tempList = List.from(_allRendezvous); // Create a mutable copy

    // Apply search filter
    if (query.isNotEmpty) {
      tempList = tempList.where((rv) {
        final vetNameLower = rv.vetName.toLowerCase();
        final animalNameLower = rv.animalName.toLowerCase();
        return vetNameLower.contains(query) || animalNameLower.contains(query);
      }).toList();
    }

    // Apply sort order
    tempList.sort((a, b) {
      switch (_currentSortOrder) {
        case RendezvousSortOrder.dateDesc:
          return b.date.compareTo(a.date);
        case RendezvousSortOrder.dateAsc:
          return a.date.compareTo(b.date);
        case RendezvousSortOrder.vetAsc:
          return a.vetName.toLowerCase().compareTo(b.vetName.toLowerCase());
        case RendezvousSortOrder.animalAsc:
          return a.animalName.toLowerCase().compareTo(b.animalName.toLowerCase());
        default:
          return 0;
      }
    });

    setState(() {
      _filteredRendezvousList = tempList;
    });
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _onSortSelected(RendezvousSortOrder order) {
    setState(() {
      _currentSortOrder = order;
      _applyFiltersAndSort();
    });
  }

  Future<void> _refreshRendezvous() async {
    // Re-fetch all data and then apply filters/sort
    await _fetchRendezvous();
  }

  String _getStatusText(RendezvousStatus status) {
    switch (status) {
      case RendezvousStatus.confirme:
        return 'Confirmed';
      case RendezvousStatus.annule:
        return 'Cancelled';
      case RendezvousStatus.termine:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(RendezvousStatus status) {
    switch (status) {
      case RendezvousStatus.confirme:
        return Colors.green.shade600;
      case RendezvousStatus.annule:
        return Colors.red.shade600;
      case RendezvousStatus.termine:
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _deleteRendezvous(String id) async {
    try {
      await _deleteRendezvousService.deleteRendezvous(id);
      _showSnackBar('Appointment cancelled successfully!', isSuccess: true);
      _refreshRendezvous();
    } catch (e) {
      _showSnackBar('Failed to cancel appointment: $e', isSuccess: false);
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
        backgroundColor: isSuccess ? kPrimaryBlue : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildRendezvousCard(Rendezvous rv, TextTheme textTheme) {
    final formattedDate = DateFormat('dd MMM, HH:mm').format(rv.date); // More readable date format
    final statusText = _getStatusText(rv.status);
    final statusColor = _getStatusColor(rv.status);

    return Card(
      elevation: 6, // More pronounced shadow
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
      color: Colors.white, // White card background
      child: InkWell( // Added InkWell for ripple effect
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Optional: Show more details in a dialog if needed
          _showRendezvousDetailsDialog(rv, textTheme);
        },
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 22, color: kAccentBlue), // Themed icon
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue, // Themed date
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15), // Light background for status
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1), // Border matching status color
                    ),
                    child: Text(
                      statusText,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15), // Spacing
              Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade100), // Themed divider
              const SizedBox(height: 15),

              _buildInfoRow(textTheme, Icons.person_pin, 'Veterinary', rv.vetName),
              const SizedBox(height: 8),
              _buildInfoRow(textTheme, Icons.pets_rounded, 'Animal', rv.animalName),
              const SizedBox(height: 8),
              // Removed the line trying to access rv.reason
              // _buildInfoRow(textTheme, Icons.description_rounded, 'Reason', rv.reason),

              const SizedBox(height: 20),

              // Action buttons for each card
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: kAccentBlue, size: 26),
                      tooltip: 'Change Appointment',
                      onPressed: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpdateRendezvousPage(),
                            settings: RouteSettings(arguments: {
                              'rendezvous': rv,
                              'vetName': rv.vetName,
                            }),
                          ),
                        );
                        if (shouldRefresh == true) {
                          _refreshRendezvous();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 26),
                      tooltip: 'Cancel Appointment',
                      onPressed: () => _confirmDelete(context, rv), // Use themed dialog
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for info rows within the card
  Widget _buildInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: kPrimaryBlue.withOpacity(0.8)), // Themed icon
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  // Custom confirmation dialog for delete/cancel
  Future<void> _confirmDelete(BuildContext context, Rendezvous rv) async {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange.shade400, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Confirm Cancellation', // Clearer title
                  style: textTheme.headlineSmall?.copyWith(color: kPrimaryBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to cancel your appointment with ${rv.vetName} on ${DateFormat('dd MMM, HH:mm').format(rv.date)}?',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          side: const BorderSide(color: kPrimaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('No', style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600, // Red for cancel action
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                        ),
                        child: Text('Yes, Cancel', style: textTheme.labelLarge),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      _deleteRendezvous(rv.id);
    }
  }

  // Optional: Dialog to show more details on card tap
  void _showRendezvousDetailsDialog(Rendezvous rv, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note_rounded, color: kPrimaryBlue, size: 40),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Appointment Details',
                        style: textTheme.headlineSmall?.copyWith(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade100),
                const SizedBox(height: 20),
                _buildDetailRowInDialog(textTheme, 'Date', DateFormat('dd MMM, HH:mm').format(rv.date)),
                _buildDetailRowInDialog(textTheme, 'Status', _getStatusText(rv.status)),
                _buildDetailRowInDialog(textTheme, 'Veterinarian', rv.vetName),
                _buildDetailRowInDialog(textTheme, 'Animal', rv.animalName),
                // Removed the line trying to access rv.reason
                // _buildDetailRowInDialog(textTheme, 'Reason', rv.reason),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: Text('Close', style: textTheme.labelLarge),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper for detail rows in dialog
  Widget _buildDetailRowInDialog(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryBlue),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
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
      backgroundColor: Colors.grey.shade50, // Consistent light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue, // Themed AppBar background
        foregroundColor: Colors.white, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'My Appointments', // Themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Scheduled Appointments', // More descriptive title
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 15),
                // Search and Sort Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by vet or animal name...',
                          prefixIcon: Icon(Icons.search_rounded, color: kPrimaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<RendezvousSortOrder>(
                      onSelected: _onSortSelected,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: RendezvousSortOrder.dateDesc,
                          child: Text('Date (Newest First)', style: textTheme.bodyMedium),
                        ),
                        PopupMenuItem(
                          value: RendezvousSortOrder.dateAsc,
                          child: Text('Date (Oldest First)', style: textTheme.bodyMedium),
                        ),
                        PopupMenuItem(
                          value: RendezvousSortOrder.vetAsc,
                          child: Text('Vet Name (A-Z)', style: textTheme.bodyMedium),
                        ),
                        PopupMenuItem(
                          value: RendezvousSortOrder.animalAsc,
                          child: Text('Animal Name (A-Z)', style: textTheme.bodyMedium),
                        ),
                      ],
                      icon: Icon(Icons.sort_rounded, color: kPrimaryBlue, size: 30),
                      tooltip: 'Sort Appointments',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, // Make button full width
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VetListPage(username: widget.username),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_circle_outline_rounded, color: Colors.white), // Themed icon
                    label: Text(
                      'Schedule New Appointment', // Clearer action text
                      style: textTheme.labelLarge,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue, // Use accent blue for this button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // More rounded
                      ),
                      elevation: 6, // Subtle shadow
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshRendezvous,
              color: kPrimaryBlue, // Themed refresh indicator
              child: FutureBuilder<List<Rendezvous>>(
                future: _rendezvousFuture, // Still watch the original future
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
                              'Failed to load appointments: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _refreshRendezvous,
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
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_rounded, color: Colors.grey.shade400, size: 80),
                          const SizedBox(height: 16),
                          Text(
                            'No appointments scheduled yet.',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VetListPage(username: widget.username),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Schedule Now', style: textTheme.labelLarge),
                          ),
                        ],
                      ),
                    );
                  }

                  // Use the filtered list for display
                  if (_filteredRendezvousList.isEmpty && _searchController.text.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_off_rounded, color: Colors.grey.shade400, size: 80),
                            const SizedBox(height: 16),
                            Text(
                              'No appointments match your search.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredRendezvousList.length,
                    itemBuilder: (context, index) =>
                        _buildRendezvousCard(_filteredRendezvousList[index], textTheme), // Pass textTheme
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}