import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/models/rendezvous_models/rendezvous_model.dart';
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart';
import '../components/home_navbar.dart';

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

  // New method to fetch and sort rendezvous
  Future<List<RendezVousModel>> _fetchAndSortRendezVous() async {
    final rendezVousList = await _service.getRendezVousList(widget.token);
    // Sort from newest to oldest date
    rendezVousList.sort((a, b) {
      try {
        final DateTime dateA = DateTime.parse(a.date);
        final DateTime dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        // Handle cases where date string might be invalid
        return 0; // Don't sort if dates are unparseable
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

  Widget getStatusWidget(String status) {
    int statusValue = int.tryParse(status) ?? -1;

    Color statusColor;
    String statusText;

    switch (statusValue) {
      case 0:
        statusText = 'Confirmed';
        statusColor = Colors.green;
        break;
      case 1:
        statusText = 'Canceled';
        statusColor = Colors.red;
        break;
      case 2:
        statusText = 'Terminated';
        statusColor = Colors.orange;
        break;
      default:
        statusText = 'Unknown';
        statusColor = Colors.grey;
    }

    return Text(
      statusText,
      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
    );
  }

  void showEditStatusDialog(RendezVousModel rdv) {
    int selectedStatus = int.tryParse(rdv.status) ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<int>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Confirmed')),
                  DropdownMenuItem(value: 1, child: Text('Canceled')),
                  DropdownMenuItem(value: 2, child: Text('Terminated')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status updated successfully'),
                    ),
                  );
                  setState(() {
                    // Re-fetch and re-sort the list after an update
                    _rdvFuture = _fetchAndSortRendezVous();
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RendezVousModel>>(
              future: _rdvFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No rendez-vous found.'));
                } else {
                  // The data is already sorted by _fetchAndSortRendezVous()
                  final rdvs = snapshot.data!;
                  return ListView.builder(
                    itemCount: rdvs.length,
                    itemBuilder: (context, index) {
                      final rdv = rdvs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: ${formatDate(rdv.date)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Display the client name correctly
                              Text('Client: ${rdv.clientName}'),
                              // Display the animal name correctly
                              Text('Animal: ${rdv.animalName}'),
                              getStatusWidget(rdv.status),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => showEditStatusDialog(rdv),
                                child: const Text('Edit Status'),
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