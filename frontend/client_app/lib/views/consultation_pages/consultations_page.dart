import 'dart:io';

import 'package:client_app/models/consultation_models/consultation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/consultation_services/consultation_service.dart';
import 'package:client_app/utils/logout_helper.dart';
import '../components/home_navbar.dart';

Future<bool> requestPermissions() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      print("Permission status: $status");
      return status.isGranted;
    }
  }
  return true;
}

Future<void> downloadFile(
    String url, String filename, BuildContext context) async {
  final hasPermission = await requestPermissions();
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage permission denied')),
    );
    return;
  }

  try {
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final savePath = '${directory.path}/$filename';
    final dio = Dio();
    await dio.download(url, savePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded to: $savePath'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('Download error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Download failed'), backgroundColor: Colors.red),
    );
  }
}

class ConsultationsPage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const ConsultationsPage({
    Key? key,
    required this.username,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  late Future<List<Consultation>> _consultationsFuture;
  final ConsultationService _consultationService = ConsultationService();

  @override
  void initState() {
    super.initState();
    _consultationsFuture = _fetchAndSortConsultations();
  }

  Future<List<Consultation>> _fetchAndSortConsultations() async {
    List<Consultation> consultations =
        await _consultationService.getConsultationsList();

    consultations.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a.date);
        DateTime dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        return 0;
      }
    });

    return consultations;
  }

  String formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (e) {
      return rawDate;
    }
  }

  String extractFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Consultation>>(
              future: _consultationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No consultations found.'));
                } else {
                  final consultations = snapshot.data!;
                  return ListView.builder(
                    itemCount: consultations.length,
                    itemBuilder: (context, index) {
                      final consultation = consultations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatDate(consultation.date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Vétérinaire: ${consultation.vetName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('Animal: ${consultation.petName}'),
                              const SizedBox(height: 8),
                              const Divider(),
                              Text('Diagnostic:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                consultation.diagnostic,
                                softWrap: true,
                                maxLines: null,
                              ),
                              const SizedBox(height: 6),
                              Text('Traitement:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                consultation.treatment,
                                softWrap: true,
                                maxLines: null,
                              ),
                              const SizedBox(height: 6),
                              Text('Prescription:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                consultation.prescription,
                                softWrap: true,
                                maxLines: null,
                              ),
                              const SizedBox(height: 6),
                              Text('Notes:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                consultation.notes,
                                softWrap: true,
                                maxLines: null,
                              ),
                              const SizedBox(height: 8),
                              if (consultation.documentPath.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        extractFileName(
                                            consultation.documentPath),
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded),
                                      onPressed: () {
                                        downloadFile(
                                            consultation.documentPath,
                                            extractFileName(
                                                consultation.documentPath),
                                            context);
                                      },
                                    ),
                                  ],
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
