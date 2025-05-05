import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';
import 'package:veterinary_app/models/rendezvous_models/rendezvous_model.dart';
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart';
import 'package:intl/intl.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';

class UpdateConsultationPage extends StatefulWidget {
  final String token;
  final String username;
  final Consultation consultation;

  const UpdateConsultationPage({
    super.key,
    required this.token,
    required this.username,
    required this.consultation,
  });

  @override
  _UpdateConsultationPageState createState() => _UpdateConsultationPageState();
}

class _UpdateConsultationPageState extends State<UpdateConsultationPage> {
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
    _fillFormWithConsultationData();
  }

  void _fillFormWithConsultationData() {
    final consult = widget.consultation;
    _dateController.text = consult.date.toIso8601String().split('T')[0];
    _diagnosticController.text = consult.diagnostic;
    _treatmentController.text = consult.treatment;
    _prescriptionController.text = consult.prescription;
    _notesController.text = consult.notes;
    // _selectedRendezVousId = consult.rendezVousId.toString();
    // Document handling: not pre-filled, user can upload new document if needed
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

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRendezVousId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rendez-vous.')),
        );
        return;
      }

      try {
        final uri = Uri.parse('https://10.0.2.2:5000/api/consultations/${widget.consultation.id}');

        var request = http.MultipartRequest('PUT', uri)
          ..headers['Authorization'] = 'Bearer ${widget.token}'
          ..fields['Date'] = _dateController.text
          ..fields['Diagnostic'] = _diagnosticController.text
          ..fields['Treatment'] = _treatmentController.text
          ..fields['Prescription'] = _prescriptionController.text
          ..fields['Notes'] = _notesController.text
          ..fields['RendezVousID'] = _selectedRendezVousId!;

        if (_document != null) {
          request.files.add(
            await http.MultipartFile.fromPath('Document', _document!.path),
          );
        }

        final response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consultation updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          final body = await response.stream.bytesToString();
          throw Exception('Failed with ${response.statusCode}: $body');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
                    initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
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
                    (value) => value!.isEmpty ? 'Please enter a diagnostic' : null,
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
                    (value) => value!.isEmpty ? 'Please enter a prescription' : null,
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
                items: _rendezVousList.map((rv) {
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
                    (value) => value == null ? 'Please select a rendez-vous' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitUpdate,
                child: const Text('Update Consultation'),
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
