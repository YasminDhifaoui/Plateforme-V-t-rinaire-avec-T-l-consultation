class VaccinationModel {
  final String id;
  final String animalId;
  final String vaccineName;
  final DateTime date;
  final String veterinarianId;

  VaccinationModel({
    required this.id,
    required this.animalId,
    required this.vaccineName,
    required this.date,
    required this.veterinarianId,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] ?? '',
      animalId: json['animalId'] ?? '',
      vaccineName: json['Name'] ?? json['vaccineName'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      veterinarianId: json['veterinarianId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animalId': animalId,
      'Name': vaccineName,
      'date': date.toIso8601String(),
      'veterinarianId': veterinarianId,
    };
  }
}
