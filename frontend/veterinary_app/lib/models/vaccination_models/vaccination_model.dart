import 'package:veterinary_app/models/animal_models/animal_model.dart';

class VaccinationModel {
  final String id;
  final String animalId;
  final String name;
  final DateTime date;
  final String veterinarianId;
  final AnimalModel? animal;

  VaccinationModel({
    required this.id,
    required this.animalId,
    required this.name,
    required this.date,
    required this.veterinarianId,
    this.animal,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] ?? 0,
      animalId: json['animalId'] ?? '',
      name: json['name'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      veterinarianId: json['veterinarianId'] ?? '',
      animal: json['animal'] != null ? AnimalModel.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animalId': animalId,
      'name': name,
      'date': date.toIso8601String(),
      'veterinarianId': veterinarianId,
      'animal': animal?.toJson(),
    };
  }
}
