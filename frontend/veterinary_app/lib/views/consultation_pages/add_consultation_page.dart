import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import 'package:veterinary_app/models/client_models/client_model.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';

import '../../utils/base_url.dart';

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
  String? _selectedClientId;
  List<ClientModel> _clientList = [];
  final ClientService _clientService = ClientService();

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final clients = await _clientService.getAllClients(widget.token);
      setState(() {
        _clientList = clients;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching clients: $e')));
    }
  }

  Future<void> _pickDocument() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      setState(() {
        _document = File(file.path);
      });
    }
  }

  Future<void> _submitConsultation() async {
    if (_formKey.currentState!.validate()) {
      if (_document == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a document.')),
        );
        return;
      }

      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client.')),
        );
        return;
      }

      try {
        final uri = Uri.parse(
          '${BaseUrl.api}/api/vet/consultationsvet/create-consultation',
        );

        var request =
            http.MultipartRequest('POST', uri)
              ..headers['Authorization'] = 'Bearer ${widget.token}'
              ..fields['Date'] = _dateController.text
              ..fields['Diagnostic'] = _diagnosticController.text
              ..fields['Treatment'] = _treatmentController.text
              ..fields['Prescription'] = _prescriptionController.text
              ..fields['Notes'] = _notesController.text
              ..fields['ClientID'] = _selectedClientId!
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
                value: _selectedClientId,
                items:
                    _clientList.map((client) {
                      return DropdownMenuItem<String>(
                        value: client.id.toString(),
                        child: Text(client.username),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Select Client'),
                validator:
                    (value) => value == null ? 'Please select a client' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _document == null
                      ? 'Choose Document'
                      : 'Selected: ${_document!.path.split('/').last}',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitConsultation,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, true),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Return'),
      ),
    );
  }
}
