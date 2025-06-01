import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:path_provider/path_provider.dart';
import 'package:veterinary_app/models/consultation_models/consulattion_model.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';

import '../../utils/base_url.dart';

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
  final TextEditingController _clientNameController = TextEditingController();

  File? _document;
  String? _existingDocumentName;
  String? _clientIdToSubmit;

  final ImagePicker _picker = ImagePicker();

  // New variable to store the selected DateTime object (date + time)
  DateTime? _selectedConsultationDateTime;

  @override
  void initState() {
    super.initState();
    _fillFormWithConsultationData();
  }

  void _fillFormWithConsultationData() {
    final consult = widget.consultation;

    // Parse the existing date string into a DateTime object
    // Assuming consult.date is already a DateTime object from your model
    _selectedConsultationDateTime = consult.date;
    _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(consult.date); // Format for display

    _diagnosticController.text = consult.diagnostic;
    _treatmentController.text = consult.treatment;
    _prescriptionController.text = consult.prescription;
    _notesController.text = consult.notes;

    _clientNameController.text = consult.clientName ?? 'Unknown Client';
    _clientIdToSubmit = consult.clientId;

    if (consult.documentPath != null && consult.documentPath!.isNotEmpty) {
      _existingDocumentName = consult.documentPath!.split('\\').last;
    }
  }

  Future<void> _pickDocument() async {
    final typeGroup =
    XTypeGroup(label: 'documents', extensions: ['pdf', 'jpg', 'png', 'doc', 'docx']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      setState(() {
        _document = File(file.path);
        _existingDocumentName = file.name;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _document = File(photo.path);
        _existingDocumentName = photo.name;
      });
    }
  }

  // New method to handle date and time picking for update
  Future<void> _selectDateAndTime(BuildContext context) async {
    // Initial date for the picker, defaults to current date/time if none selected
    DateTime initialDate = _selectedConsultationDateTime ?? DateTime.now();

    // 1. Show Date Picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // 2. Show Time Picker if a date was picked
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate), // Use initialDate for initial time
      );

      if (pickedTime != null) {
        // Combine the picked date and time
        final combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedConsultationDateTime = combinedDateTime;
          // Format the combined DateTime for display in the TextFormField
          _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        });
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_clientIdToSubmit == null || _clientIdToSubmit!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client ID is missing. Cannot update consultation.')),
          );
        }
        return;
      }
      // Validate that a date and time has been selected
      if (_selectedConsultationDateTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date and time for the consultation.')),
          );
        }
        return;
      }

      try {
        final uri = Uri.parse('${BaseUrl.api}/api/vet/consultationsvet/update-consultation/${widget.consultation.id}');

        var request = http.MultipartRequest('PUT', uri)
          ..headers['Authorization'] = 'Bearer ${widget.token}'
        // Use the _selectedConsultationDateTime for the 'Date' field
          ..fields['Date'] = _selectedConsultationDateTime!.toIso8601String()
          ..fields['Diagnostic'] = _diagnosticController.text
          ..fields['Treatment'] = _treatmentController.text
          ..fields['Prescription'] = _prescriptionController.text
          ..fields['Notes'] = _notesController.text
          ..fields['ClientId'] = _clientIdToSubmit!;

        // --- Document handling logic ---
        if (_document != null) {
          request.files.add(
            await http.MultipartFile.fromPath('Document', _document!.path),
          );
        } else if (widget.consultation.documentPath != null && widget.consultation.documentPath!.isNotEmpty) {
          request.fields['ExistingDocumentPath'] = widget.consultation.documentPath!;
        }

        final response = await request.send();

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Consultation updated successfully')),
            );
            Navigator.pop(context, true);
          }
        } else {
          final body = await response.stream.bytesToString();
          throw Exception('Failed with ${response.statusCode}: $body');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        }
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
    _clientNameController.dispose();
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
              // Date and Time TextFormField
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date and Time (YYYY-MM-DD HH:MM)', // Updated label
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDateAndTime(context), // Call the new method
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date and time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _diagnosticController,
                decoration: const InputDecoration(labelText: 'Diagnostic'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a diagnostic' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _treatmentController,
                decoration: const InputDecoration(labelText: 'Treatment'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter treatment' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _prescriptionController,
                decoration: const InputDecoration(labelText: 'Prescription'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a prescription' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter notes' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                readOnly: true, // Client name is read-only for update
              ),

              const SizedBox(height: 16),

              Text(
                _existingDocumentName != null && _existingDocumentName!.isNotEmpty
                    ? 'Selected Document: $_existingDocumentName'
                    : 'No document selected',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),

              // Row for Pick File and Take Photo buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

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
              Navigator.pop(context);
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