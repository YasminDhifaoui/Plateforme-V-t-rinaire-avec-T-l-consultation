class Animal {
  final String id;
  final String name;
  final String espece;
  final String race;
  final int age;
  final String sexe;
  final String allergies;
  final String antecedentsmedicaux;

  Animal({
    required this.id,
    required this.name,
    required this.espece,
    required this.race,
    required this.age,
    required this.sexe,
    required this.allergies,
    required this.antecedentsmedicaux,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      espece: json['espece'] ?? '',
      race: json['race'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age'].toString()) ?? 0,
      sexe: json['sexe'] ?? '',
      allergies: json['allergies'] ?? '',
      antecedentsmedicaux: json['anttecedentsmedicaux'] ?? '',
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
      'anttecedentsmedicaux': antecedentsmedicaux, // lowercase, double 't'
    };
  }
}
