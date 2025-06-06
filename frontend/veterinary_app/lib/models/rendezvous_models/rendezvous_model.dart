// models/rendezvous_models/rendezvous_model.dart
class RendezVousModel {
  final String id;
  final String status;
  final String date;
  final String clientName;
  final String animalName;

  RendezVousModel({
    required this.id,
    required this.status,
    required this.date,
    required this.clientName,
    required this.animalName,
  });

  factory RendezVousModel.fromJson(Map<String, dynamic> json) {
    // Safely extract client name
    String extractedClientName = 'Unknown';
    if (json['client'] != null) {
      if (json['client']['userName'] != null) {
        extractedClientName = json['client']['userName'].toString();
      } else if (json['client']['firstName'] != null && json['client']['lastName'] != null) {
        extractedClientName = '${json['client']['firstName']} ${json['client']['lastName']}';
      }
    }

    // Safely extract animal name
    String extractedAnimalName = 'Unknown';
    if (json['animal'] != null && json['animal']['nom'] != null) {
      extractedAnimalName = json['animal']['nom'].toString();
    }

    return RendezVousModel(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? 'Unknown',
      date: json['date']?.toString() ?? '',
      clientName: extractedClientName,
      animalName: extractedAnimalName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'date': date,
      'clientName': clientName,
      'animalName': animalName,
    };
  }
}