import 'dart:io';

import 'package:client_app/models/consultation_models/consultation.dart';
import 'package:client_app/utils/base_url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/consultation_services/consultation_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Import your blue color constants. Ensure these are correctly defined.
// If your colors are in a different file (e.g., constants.dart), adjust this import:
import 'package:client_app/main.dart';

// Enum for sorting options
enum SortOrder { newest, oldest }

Future<bool> requestPermissions() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      print("Permission status: $status"); // For debugging
      return status.isGranted;
    }
  }
  return true; // Assume iOS/other platforms don't need explicit storage permission handling this way
}

Future<void> downloadFile(
    String url, String filename, BuildContext context) async {
  final hasPermission = await requestPermissions();
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Storage permission denied. Cannot download file.'),
          backgroundColor: Colors.red),
    );
    return;
  }

  try {
    // Standard download directory for Android
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final savePath = '${directory.path}/$filename';
    final dio = Dio();
    await dio.download(url, savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
                'Download Progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded to: $savePath'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  } catch (e) {
    debugPrint('Download error: $e');
    String errorMessage = 'Download failed.';
    if (e is DioException) {
      if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'File not found or server error.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Network error. Check your connection.';
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10)),
    );
  }
}

class ConsultationsPage extends StatefulWidget {
  final String username;

  const ConsultationsPage({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  late Future<List<Consultation>> _initialConsultationsFuture;
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _searchController = TextEditingController();

  List<Consultation> _allConsultations = [];
  List<Consultation> _filteredConsultations = [];
  SortOrder _currentSortOrder = SortOrder.newest; // Default sort order

  @override
  void initState() {
    super.initState();
    _initialConsultationsFuture = _fetchInitialConsultations();
    _searchController.addListener(_filterConsultations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterConsultations);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Consultation>> _fetchInitialConsultations() async {
    try {
      final consultations = await _consultationService.getConsultationsList();
      setState(() {
        _allConsultations = consultations;
        _sortAndFilterConsultations(); // Apply initial sort and filter
      });
      return consultations;
    } catch (e) {
      _showSnackBar("Failed to load consultations. Please try again.", isSuccess: false);
      rethrow;
    }
  }

  void _sortAndFilterConsultations() {
    List<Consultation> tempFilteredList = List.from(_allConsultations); // Create a mutable copy

    // Apply search filter first
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempFilteredList = tempFilteredList.where((consultation) {
        return consultation.vetName.toLowerCase().contains(query) ||
            consultation.diagnostic.toLowerCase().contains(query) ||
            consultation.treatment.toLowerCase().contains(query) ||
            consultation.prescription.toLowerCase().contains(query) ||
            consultation.notes.toLowerCase().contains(query) ||
            formatDate(consultation.date).toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    tempFilteredList.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a.date);
        DateTime dateB = DateTime.parse(b.date);
        return _currentSortOrder == SortOrder.newest
            ? dateB.compareTo(dateA) // Newest first
            : dateA.compareTo(dateB); // Oldest first
      } catch (e) {
        // Fallback for invalid date format, maintain original order
        return 0;
      }
    });

    setState(() {
      _filteredConsultations = tempFilteredList;
    });
  }

  void _filterConsultations() {
    _sortAndFilterConsultations(); // Trigger re-sort and filter on search input change
  }

  String formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (e) {
      return rawDate; // Return original if parsing fails
    }
  }

  String extractFileName(String path) {
    return path.split('/').last;
  }

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
      backgroundColor: Colors.grey.shade50, // Light background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'My Consultations',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search consultations...',
                      hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                      prefixIcon: Icon(Icons.search, color: kPrimaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          _filterConsultations(); // Clear filter
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
                const SizedBox(width: 10),
                PopupMenuButton<SortOrder>(
                  icon: Icon(Icons.sort, color: kPrimaryBlue, size: 28),
                  onSelected: (SortOrder result) {
                    setState(() {
                      _currentSortOrder = result;
                      _sortAndFilterConsultations(); // Re-sort and filter
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOrder>>[
                    PopupMenuItem<SortOrder>(
                      value: SortOrder.newest,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: _currentSortOrder == SortOrder.newest ? kPrimaryBlue : Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            'Newest First',
                            style: textTheme.bodyLarge?.copyWith(
                              color: _currentSortOrder == SortOrder.newest ? kPrimaryBlue : Colors.black87,
                              fontWeight: _currentSortOrder == SortOrder.newest ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortOrder>(
                      value: SortOrder.oldest,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: _currentSortOrder == SortOrder.oldest ? kPrimaryBlue : Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            'Oldest First',
                            style: textTheme.bodyLarge?.copyWith(
                              color: _currentSortOrder == SortOrder.oldest ? kPrimaryBlue : Colors.black87,
                              fontWeight: _currentSortOrder == SortOrder.oldest ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  color: Colors.white, // Background of the popup menu
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 8,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Consultation>>(
              future: _initialConsultationsFuture,
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
                            "Failed to load consultations: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _initialConsultationsFuture = _fetchInitialConsultations();
                                _searchController.clear(); // Clear search on retry
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
                } else if (_allConsultations.isEmpty) { // No consultations found at all
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, color: Colors.grey.shade400, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          "No consultations recorded yet.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initialConsultationsFuture = _fetchInitialConsultations();
                              _searchController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Refresh List', style: textTheme.labelLarge),
                        ),
                      ],
                    ),
                  );
                } else if (_filteredConsultations.isEmpty && _searchController.text.isNotEmpty) {
                  // No consultations matching search query
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          "No consultations match your search.",
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Try a different keyword or clear your search.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    itemCount: _filteredConsultations.length,
                    itemBuilder: (context, index) {
                      final consultation = _filteredConsultations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(18.0), // Increased padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 20, color: kAccentBlue),
                                  const SizedBox(width: 10),
                                  Text(
                                    formatDate(consultation.date),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 8), // Added spacing below date
                              // VETERINARIAN NAME DISPLAY - RESTORED AND STYLED
                              Row(
                                children: [
                                  Icon(Icons.person_pin, size: 20, color: kAccentBlue), // Consistent icon size
                                  const SizedBox(width: 10),
                                  Text(
                                    'Vétérinaire: ${consultation.vetName}',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade100),
                              const SizedBox(height: 12),

                              _buildInfoRow(textTheme, 'Diagnostic:', consultation.diagnostic),
                              _buildInfoRow(textTheme, 'Treatment:', consultation.treatment),
                              _buildInfoRow(textTheme, 'Prescription:', consultation.prescription),
                              _buildInfoRow(textTheme, 'Notes:', consultation.notes),

                              if (consultation.documentPath.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade100),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.attach_file, color: kPrimaryBlue),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        extractFileName(consultation.documentPath),
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.black54),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download_rounded, color: kAccentBlue),
                                      tooltip: 'Download Document',
                                      onPressed: () {
                                        downloadFile(
                                          '${BaseUrl.api}/${consultation.documentPath}',
                                          extractFileName(consultation.documentPath),
                                          context,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_red_eye_rounded, color: kAccentBlue),
                                      tooltip: 'View Document',
                                      onPressed: () async {
                                        try {
                                          final Uri uri = Uri.parse(
                                            '${BaseUrl.api}/${consultation.documentPath}',
                                          );
                                          if (!await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          )) {
                                            _showSnackBar(
                                              'Could not open document. Check if you have an app to handle this file type.',
                                              isSuccess: false,
                                            );
                                          }
                                        } catch (e) {
                                          _showSnackBar(
                                            'Error viewing document: ${e.toString()}',
                                            isSuccess: false,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildInfoRow(TextTheme textTheme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink(); // Don't show if empty

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Spacing between rows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue, // Themed label
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            maxLines: null,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}