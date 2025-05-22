class Consultation {
  final String id;
  final DateTime date;
  final String diagnostic;
  final String treatment;
  final String prescription;
  final String notes;
  final String documentPath;
  final String clientId;

  final String clientName;
  final String animalId;
  final String animalName;

  Consultation({
    required this.id,
    required this.date,
    required this.diagnostic,
    required this.treatment,
    required this.prescription,
    required this.notes,
    required this.documentPath,
    required this.clientId,
    required this.clientName,
    required this.animalId,
    required this.animalName,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']??'',
      date: DateTime.parse(json['date']??''),
      diagnostic: json['diagnostic']??'',
      treatment: json['treatment']??'',
      prescription: json['prescription']??'',
      notes: json['notes']??'',
      clientId: json['clientId']??'',
      documentPath: json['documentPath']??'',
      clientName: json['clientName']??'',
      animalId: json['animalId']??'',
      animalName:
          json['animalName'] ?? '', // <-- make sure this line is present!
    );
  }
}
