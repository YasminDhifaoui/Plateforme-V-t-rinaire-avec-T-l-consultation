import 'package:veterinary_app/models/client_models/client_model.dart';

class AnimalModel {
  final String id;
  final String name;
  final String espece;
  final String race;
  final int age;
  final String sexe;
  final String allergies;
  final String anttecedentsmedicaux;
  final String ownerId;
  final ClientModel? owner;

  AnimalModel({
    required this.id,
    required this.name,
    required this.espece,
    required this.race,
    required this.age,
    required this.sexe,
    required this.allergies,
    required this.anttecedentsmedicaux,
    required this.ownerId,
    this.owner,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'] ?? '',
      name: json['nom'] ?? json['name'] ?? '',
      espece: json['espece'] ?? '',
      race: json['race'] ?? '',
      age: json['age'] ?? 0,
      sexe: json['sexe'] ?? '',
      allergies: json['allergies'] ?? '',
      anttecedentsmedicaux: json['anttecedentsmedicaux'] ?? '',
      ownerId: json['ownerId'] ?? '',
      owner: json['owner'] != null ? ClientModel.fromJson(json['owner']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'espece': espece,
      'race': race,
      'age': age,
      'sexe': sexe,
      'allergies': allergies,
      'anttecedentsmedicaux': anttecedentsmedicaux,
      'ownerId': ownerId,
      'owner': owner?.toJson(),
    };
  }
}
