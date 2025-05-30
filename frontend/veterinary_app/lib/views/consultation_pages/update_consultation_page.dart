
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:path_provider/path_provider.dart'; // Import path_provider for temporary files
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

File? _document; // Represents a NEWLY selected or captured file
String? _existingDocumentName;
String? _clientIdToSubmit;

final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker

@override
void initState() {
super.initState();
_fillFormWithConsultationData();
}

void _fillFormWithConsultationData() {
final consult = widget.consultation;
_dateController.text = consult.date.toIso8601String().split('T')[0];
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
final typeGroup = XTypeGroup(label: 'documents', extensions: ['pdf', 'jpg', 'png', 'doc', 'docx']);
final file = await openFile(acceptedTypeGroups: [typeGroup]);

if (file != null) {
setState(() {
_document = File(file.path);
_existingDocumentName = file.name;
});
}
}

// New method to take a photo
Future<void> _takePhoto() async {
final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

if (photo != null) {
setState(() {
_document = File(photo.path);
_existingDocumentName = photo.name; // Use the name generated by image_picker
});
}
}

Future<void> _submitUpdate() async {
if (_formKey.currentState!.validate()) {
if (_clientIdToSubmit == null || _clientIdToSubmit!.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Client ID is missing. Cannot update consultation.')),
);
return;
}

try {
final uri = Uri.parse('${BaseUrl.api}/api/vet/consultationsvet/update-consultation/${widget.consultation.id}');

var request = http.MultipartRequest('PUT', uri)
..headers['Authorization'] = 'Bearer ${widget.token}'
..fields['Date'] = _dateController.text
..fields['Diagnostic'] = _diagnosticController.text
..fields['Treatment'] = _treatmentController.text
..fields['Prescription'] = _prescriptionController.text
..fields['Notes'] = _notesController.text
..fields['ClientId'] = _clientIdToSubmit!;

// --- Document handling logic ---
if (_document != null) {
// A new document (from file picker or camera) was selected/captured.
request.files.add(
await http.MultipartFile.fromPath('Document', _document!.path),
);
} else if (widget.consultation.documentPath != null && widget.consultation.documentPath!.isNotEmpty) {
// No new document selected/captured, but there's an existing one on the backend.
// Send a field to tell the backend to keep the existing document.
// **Important: This assumes your backend has been modified to accept 'ExistingDocumentPath'
// or has the IFormFile? Document (nullable) property as discussed previously.**
request.fields['ExistingDocumentPath'] = widget.consultation.documentPath!;
// If your backend *still* requires a file upload even if it's the old one,
// you would uncomment and use the _downloadExistingDocument logic here instead.
// File? downloadedFile = await _downloadExistingDocument(widget.consultation.documentPath!, widget.token);
// if (downloadedFile != null) {
//   request.files.add(
//     await http.MultipartFile.fromPath('Document', downloadedFile.path),
//   );
// } else {
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(content: Text('Failed to re-upload existing document.')),
//   );
// }
}
// If _document is null AND consultation.documentPath is null/empty,
// then no 'Document' field (file or existing path) will be sent.
// This is correct if the backend accepts an optional document.

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
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Update failed: $e')),
);
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
setState(() {
_dateController.text = pickedDate.toIso8601String().split('T')[0];
});
}
},
validator: (value) => value!.isEmpty ? 'Please enter a date' : null,
),
TextFormField(
controller: _diagnosticController,
decoration: const InputDecoration(labelText: 'Diagnostic'),
validator: (value) => value!.isEmpty ? 'Please enter a diagnostic' : null,
),
TextFormField(
controller: _treatmentController,
decoration: const InputDecoration(labelText: 'Treatment'),
validator: (value) => value!.isEmpty ? 'Please enter treatment' : null,
),
TextFormField(
controller: _prescriptionController,
decoration: const InputDecoration(labelText: 'Prescription'),
validator: (value) => value!.isEmpty ? 'Please enter a prescription' : null,
),
TextFormField(
controller: _notesController,
decoration: const InputDecoration(labelText: 'Notes'),
validator: (value) => value!.isEmpty ? 'Please enter notes' : null,
),

const SizedBox(height: 16),

TextFormField(
controller: _clientNameController,
decoration: const InputDecoration(
labelText: 'Client',
border: OutlineInputBorder(),
prefixIcon: Icon(Icons.person),
),
readOnly: true,
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
const SizedBox(width: 8), // Spacing between buttons
Expanded(
child: ElevatedButton.icon(
onPressed: _takePhoto, // Call the new _takePhoto method
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