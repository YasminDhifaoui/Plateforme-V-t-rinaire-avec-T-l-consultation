// veterinary_app/models/animal_models/update_animal_vet_dto.dart

class UpdateAnimalVetDto {
  final int age;
  final String allergies;
  final String antecedentsMedicaux;

  UpdateAnimalVetDto({
    required this.age,
    required this.allergies,
    required this.antecedentsMedicaux,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'allergies': allergies,
      'antecedentsMedicaux': antecedentsMedicaux,
    };
  }
}