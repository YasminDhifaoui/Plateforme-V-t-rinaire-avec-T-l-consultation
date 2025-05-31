import 'package:veterinary_app/models/client_models/client_model.dart'; // Ensure ClientModel is correctly defined

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
  final ClientModel? owner; // Represents the full nested owner object
  final String ownerUsername; // This will hold the 'userName' from the nested 'owner'

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
    this.owner, // Make this optional in constructor as it might be null
    required this.ownerUsername, // This will be derived from 'owner'
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    // Safely parse the nested 'owner' object first
    ClientModel? parsedOwner;
    if (json['owner'] != null && json['owner'] is Map<String, dynamic>) {
      parsedOwner = ClientModel.fromJson(json['owner']);
    }

    // Extract the username from the parsedOwner, or provide a default
    // Note: The backend sends 'userName', not 'username', so access it as such.
    final String extractedUsername = parsedOwner?.username ?? parsedOwner?.username ?? 'Unknown Owner';


    return AnimalModel(
      id: json['id'] ?? '',
      name: json['nom'] ?? json['name'] ?? '', // Use 'name' if 'nom' is not found
      espece: json['espece'] ?? '',
      race: json['race'] ?? '',
      age: json['age'] ?? 0,
      sexe: json['sexe'] ?? '',
      allergies: json['allergies'] ?? '',
      anttecedentsmedicaux: json['anttecedentsmedicaux'] ?? '',
      ownerId: json['ownerId'] ?? '00000000-0000-0000-0000-000000000000', // Provide a default if null
      owner: parsedOwner, // Assign the parsed owner object
      ownerUsername: extractedUsername, // Assign the extracted username
    );
  }

  // toJson is not strictly needed if you're only deserializing,
  // but if you do need it for sending data back, here's how to structure it.
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
      // When serializing, rebuild the 'owner' object as the backend expects,
      // assuming owner.toJson() creates the correct structure including 'userName'
      'owner': owner?.toJson(),
      // 'userName' at the top level is not expected by your backend, so don't include it here
      // unless your backend API for sending animal updates specifically expects it there.
    };
  }
}