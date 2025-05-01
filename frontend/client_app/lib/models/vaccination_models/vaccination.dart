class Vaccination {
  final String id;
  final String name;
  final DateTime date;

  Vaccination({
    required this.id,
    required this.name,
    required this.date,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
