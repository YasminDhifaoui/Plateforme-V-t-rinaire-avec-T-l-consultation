class Consultation {
  final String id;
  final DateTime date;
  final String diagnostic;
  final String treatment;
  final String prescription;
  final String notes;
  final String documentPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String rendezVousId;
  final String clientName;
  final String animalId;

  Consultation({
    required this.id,
    required this.date,
    required this.diagnostic,
    required this.treatment,
    required this.prescription,
    required this.notes,
    required this.documentPath,
    required this.createdAt,
    required this.updatedAt,
    required this.rendezVousId,
    required this.clientName,
    required this.animalId,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] ?? "",
      date: DateTime.parse(json['date'] ?? ""),
      diagnostic: json['diagnostic'] ?? "",
      treatment: json['treatment'] ?? "",
      prescription: json['prescription'] ?? "",
      notes: json['notes'] ?? "",
      documentPath: json['documentPath'] ?? "",
      createdAt: DateTime.parse(json['createdAt'] ?? ""),
      updatedAt: DateTime.parse(json['updatedAt'] ?? ""),
      rendezVousId: json['rendezVousID'] ?? "",
      clientName: json['clientName'] ?? "",
      animalId: json['animalId'] ?? "",
    );
  } 
}
