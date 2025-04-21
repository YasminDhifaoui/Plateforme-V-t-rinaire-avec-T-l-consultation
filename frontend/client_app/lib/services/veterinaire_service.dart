import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/veterinaire.dart';

class VeterinaireService {
  //static const String baseUrl = "http://10.0.2.2:5000/api/client/VetsC";
  final url = Uri.parse(
    "http://10.0.2.2:5000/api/client/VetsC/get-all-veterinaires",
  );

  Future<List<Veterinaire>> getAllVeterinaires() async {
    try {
      final url = Uri.parse(
        "http://10.0.2.2:5000/api/client/VetsC/get-all-veterinaires",
      );
      final response = await http.get(url);

      print("Status code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Veterinaire.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load veterinaires');
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}
