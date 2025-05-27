import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/vaccination_models/vaccination_model.dart';
import '../../services/vaccination_services/vaccination_service.dart';
import '../components/home_navbar.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart'; // Adjust path if using a separate constants.dart file

class VaccinationByAnimalPage extends StatefulWidget {
  final String token;
  final String animalId;

  const VaccinationByAnimalPage({
    Key? key,
    required this.token,
    required this.animalId,
  }) : super(key: key);

  @override
  _VaccinationByAnimalPageState createState() => _VaccinationByAnimalPageState();
}

class _VaccinationByAnimalPageState extends State<VaccinationByAnimalPage> {
  late Future<List<VaccinationModel>> _vaccinationFuture;
  final VaccinationService _service = VaccinationService();

  @override
  void initState() {
    super.initState();
    _fetchVaccinations();
  }

  // Method to fetch vaccinations
  void _fetchVaccinations() {
    if (widget.animalId.isNotEmpty) {
      _vaccinationFuture =
          _service.getVaccinationsByAnimalId(widget.token, widget.animalId);
    } else {
      _vaccinationFuture = Future.error('Invalid animal ID provided.');
    }
  }

  // Method to refresh the vaccination list
  void _refreshVaccinationList() {
    setState(() {
      _fetchVaccinations(); // Re-trigger the future
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

  // UPDATED: Helper to format date strings, now accepts dynamic type
  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'N/A';

    DateTime? parsedDate;

    if (dateData is String) {
      try {
        parsedDate = DateTime.parse(dateData);
      } catch (e) {
        debugPrint('Error parsing date string "$dateData": $e');
        return 'Invalid Date String';
      }
    } else if (dateData is DateTime) {
      parsedDate = dateData;
    } else {
      debugPrint('Unexpected date type: ${dateData.runtimeType}');
      return 'Unexpected Date Type';
    }

    if (parsedDate != null) {
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } else {
      return 'N/A';
    }
  }


  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use themed background
      appBar: HomeNavbar(
        username: '', // You might pass the animal's name here if available from previous screen
        onLogout: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Return button (styled consistently)
          Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), // Modern back icon
                label: Text('Return', style: textTheme.labelLarge), // Themed label style
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen, // Themed background color
                  foregroundColor: Colors.white, // White icon and text
                  elevation: 6, // Add elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded shape
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Adjusted padding
                ),
              ),
            ),
          ),

          // Body with vaccination list
          Expanded(
            child: FutureBuilder<List<VaccinationModel>>(
              future: _vaccinationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryGreen)); // Themed loading indicator
                }

                if (snapshot.hasError) {
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
                            'Failed to load vaccinations: ${snapshot.error}',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshVaccinationList, // Retry button
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
                }

                final vaccinations = snapshot.data ?? [];

                if (vaccinations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vaccines_rounded, // Engaging icon for no vaccinations
                          color: kAccentGreen,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No vaccinations found for this animal.',
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add new vaccination records to see them here.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Consistent padding
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final vaccine = vaccinations[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Consistent margin
                      elevation: 8, // Consistent shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18), // Consistent rounded corners
                      ),
                      child: InkWell( // Added InkWell for tap feedback
                        borderRadius: BorderRadius.circular(18),

                        child: Padding(
                          padding: const EdgeInsets.all(20.0), // Increased padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.vaccines_rounded, color: kPrimaryGreen, size: 24), // Themed icon
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vaccine.name ?? 'Unknown Vaccine',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen, // Themed title color
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 0.8, color: Colors.grey), // Themed divider
                              _buildVaccinationInfoRow(textTheme, Icons.calendar_today_rounded, 'Date', _formatDate(vaccine.date)),
                              // Add more fields from VaccinationModel if available and relevant
                              // Example:
                              // _buildVaccinationInfoRow(textTheme, Icons.description_rounded, 'Description', vaccine.description ?? 'N/A'),
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

  // Helper widget to build consistent info rows for vaccinations
  Widget _buildVaccinationInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}