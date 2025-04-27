class Animal {
  final String id;
  final String name;
  final String species;

  Animal({
    required this.id,
    required this.name,
    required this.species,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
    );
  }
}
