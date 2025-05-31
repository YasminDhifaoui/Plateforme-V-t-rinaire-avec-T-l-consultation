import '../vet_models/veterinaire.dart';

class Consultation {
  final String id;
  final String date;
  final String diagnostic;
  final String treatment;
  final String prescription;
  final String notes;
  final String documentPath;
  final String vetName;
  final String petName;
  final Veterinaire veterinaire;

  Consultation({
    required this.id,
    required this.date,
    required this.diagnostic,
    required this.treatment,
    required this.prescription,
    required this.notes,
    required this.documentPath,
    required this.vetName,
    required this.petName,
    required this.veterinaire,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'].toString(),
      date: json['date'] ?? '',
      diagnostic: json['diagnostic'] ?? '',
      treatment: json['treatment'] ?? '',
      prescription: json['prescription'] ?? '',
      notes: json['notes'] ?? '',
      documentPath: json['documentPath'] ?? '',
      vetName: json['veterinaireName'] ?? '', // match backend field
      petName: json['animalName'] ?? '',
      veterinaire: Veterinaire.fromJson(json['veterinaire'] as Map<String, dynamic>),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'diagnostic': diagnostic,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'documentPath': documentPath,
      'veterinaireName': vetName,
      'animalName': petName,
      'Veterinaire': Veterinaire,
    };
  }
}
