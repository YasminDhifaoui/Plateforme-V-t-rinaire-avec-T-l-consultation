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
    return RendezVousModel(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      clientName:
          json['client'] != null
              ? '${json['client']['firstName']} ${json['client']['lastName']}'
              : 'Unknown',
      animalName:
          json['animal'] != null
              ? json['animal']['nom'] ?? 'Unknown'
              : 'Unknown',
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
