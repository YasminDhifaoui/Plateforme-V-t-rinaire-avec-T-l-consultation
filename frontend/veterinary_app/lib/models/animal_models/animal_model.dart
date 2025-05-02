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
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      espece: json['espece'] ?? '',
      race: json['race'] ?? '',
      age: json['age'] ?? 0,
      sexe: json['sexe'] ?? '',
      allergies: json['allergies'] ?? '',
      anttecedentsmedicaux: json['anttecedentsmedicaux'] ?? '',
      ownerId: json['ownerId'] ?? '',
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
    };
  }
}
