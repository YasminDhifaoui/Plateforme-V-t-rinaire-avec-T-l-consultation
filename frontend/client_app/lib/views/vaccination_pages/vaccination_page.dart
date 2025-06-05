import 'package:client_app/models/vaccination_models/vaccination.dart';
import 'package:client_app/services/vaccination_services/vaccination_service.dart';
import 'package:flutter/material.dart';
// import 'package:client_app/views/components/home_navbar.dart'; // Replaced with standard AppBar
// import 'package:client_app/utils/logout_helper.dart'; // Keep if used for general logout logic

// Import your blue color constants. Ensure these are correctly defined.
import 'package:client_app/main.dart';

import '../../utils/app_colors.dart'; // Adjust path if using a separate constants.dart

class VaccinationPage extends StatelessWidget {
  final String animalId;
  final String animalName;
  final String username; // Still passed, but not directly used in this page's UI after AppBar change

  const VaccinationPage({
    Key? key,
    required this.animalId,
    required this.animalName,
    required this.username,
  }) : super(key: key);

  // Helper to show themed SnackBar feedback
  void _showSnackBar(BuildContext context, String message, {bool isSuccess = true}) {
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
    final service = VaccinationService();
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
          '${animalName}\'s Vaccinations', // Clearer, themed title
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0, // No shadow
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Text(
              'Vaccination History for ${animalName}', // More descriptive title
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue, // Themed title color
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Vaccination List
          Expanded(
            child: FutureBuilder<List<Vaccination>>(
              future: service.getVaccinationsForAnimal(animalId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: kPrimaryBlue)); // Themed loading
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
                            "Failed to load vaccinations: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Trigger re-fetch (requires StatefulWidget or Riverpod/Provider)
                              // For StatelessWidget, you'd need to convert to StatefulWidget
                              // or pass a refresh callback from the parent.
                              // For now, this button won't re-trigger the FutureBuilder directly.
                              _showSnackBar(context, "Cannot refresh in StatelessWidget directly. Please navigate back and forth.", isSuccess: false);
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
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vaccines_rounded, color: Colors.grey.shade400, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          'No vaccinations recorded for ${animalName} yet.',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        // Optionally add a button to add first vaccination if that's a flow
                      ],
                    ),
                  );
                }

                final vaccinations = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final vac = vaccinations[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // More rounded corners
                      ),
                      elevation: 6, // More pronounced shadow
                      color: Colors.white, // White card background
                      child: InkWell( // Added InkWell for ripple effect
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          // Show detailed dialog
                          _showVaccinationDetailsDialog(context, vac, textTheme);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15), // Increased padding
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.shade100, // Light green background
                                  border: Border.all(color: Colors.green.shade400, width: 2), // Green border
                                ),
                                child: Icon(Icons.vaccines_rounded, color: Colors.green.shade700, size: 30), // Themed icon
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vac.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryBlue, // Themed title
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${vac.date.toLocal().toString().split(".")[0]}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: kAccentBlue), // Themed trailing icon
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

  // Custom dialog for vaccination details
  void _showVaccinationDetailsDialog(BuildContext context, Vaccination vac, TextTheme textTheme) {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.vaccines_rounded, color: Colors.green.shade600, size: 70),
                const SizedBox(height: 20),
                Text(
                  vac.name,
                  style: textTheme.headlineSmall?.copyWith(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Vaccination Details:',
                  style: textTheme.titleMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(textTheme, 'Date', vac.date.toLocal().toString().split(".")[0]),
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
  Widget _buildDetailRow(TextTheme textTheme, String label, String value) {
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
}