import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:veterinary_app/models/rendezvous_models/rendezvous_model.dart';
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
// import 'package:file_picker/file_picker.dart';

class AddConsultationPage extends StatefulWidget {
  final String token;
  final String username;

  const AddConsultationPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  _AddConsultationPageState createState() => _AddConsultationPageState();
}

class _AddConsultationPageState extends State<AddConsultationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _diagnosticController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  File? _document;
  String? _selectedRendezVousId;
  List<RendezVousModel> _rendezVousList = [];
  final RendezVousService _rendezVousService = RendezVousService();

  @override
  void initState() {
    super.initState();
    _fetchRendezVous();
  }

  Future<void> _fetchRendezVous() async {
    try {
      final rendezVousList = await _rendezVousService.getRendezVousList(
        widget.token,
      );
      setState(() {
        _rendezVousList = rendezVousList;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching rendez-vous: $e')));
    }
  }

  /*Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _document = File(result.files.single.path!);
      });
    }
  }*/

  Future<void> _submitConsultation() async {
    if (_formKey.currentState!.validate()) {
      if (_document == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a document.')),
        );
        return;
      }

      if (_selectedRendezVousId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rendez-vous.')),
        );
        return;
      }

      try {
        final uri = Uri.parse('https://10.0.2.2:5000/api/consultations');

        var request =
            http.MultipartRequest('POST', uri)
              ..headers['Authorization'] = 'Bearer ${widget.token}'
              ..fields['Date'] = _dateController.text
              ..fields['Diagnostic'] = _diagnosticController.text
              ..fields['Treatment'] = _treatmentController.text
              ..fields['Prescription'] = _prescriptionController.text
              ..fields['Notes'] = _notesController.text
              ..fields['RendezVousID'] = _selectedRendezVousId!
              ..files.add(
                await http.MultipartFile.fromPath('Document', _document!.path),
              );

        final response = await request.send();

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consultation created successfully')),
          );
          Navigator.pop(context, true);
        } else {
          final body = await response.stream.bytesToString();
          throw Exception('Failed with ${response.statusCode}: $body');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _diagnosticController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        pickedDate.toIso8601String().split('T')[0];
                    setState(() {
                      _dateController.text = formattedDate;
                    });
                  }
                },
                validator:
                    (value) => value!.isEmpty ? 'Please enter a date' : null,
              ),
              TextFormField(
                controller: _diagnosticController,
                decoration: const InputDecoration(labelText: 'Diagnostic'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter a diagnostic' : null,
              ),
              TextFormField(
                controller: _treatmentController,
                decoration: const InputDecoration(labelText: 'Treatment'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter treatment' : null,
              ),
              TextFormField(
                controller: _prescriptionController,
                decoration: const InputDecoration(labelText: 'Prescription'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter a prescription' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter notes' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRendezVousId,
                items:
                    _rendezVousList.map((rv) {
                      DateTime parsedDate =
                          DateTime.tryParse(rv.date) ?? DateTime.now();
                      String formattedDate = DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(parsedDate);
                      return DropdownMenuItem(
                        value: rv.id.toString(),
                        child: Text(
                          '${rv.clientName} | ${rv.animalName} | $formattedDate',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRendezVousId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select RendezVous',
                ),
                validator:
                    (value) =>
                        value == null ? 'Please select a rendez-vous' : null,
              ),
              const SizedBox(height: 16),
              /* ElevatedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _document == null ? 'Choose Document' : 'Document Selected',
                ),
              ), */
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitConsultation,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'returnBtn',
            onPressed: () {
              Navigator.pop(context); // Go back
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Return'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
