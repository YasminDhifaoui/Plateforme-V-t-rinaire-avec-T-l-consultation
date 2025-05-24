import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veterinary_app/models/product_models/product_model.dart';
// Import your BaseUrl class
import 'package:veterinary_app/utils/base_url.dart';

class ProductService {
  // Remove the 'baseUrl' final field and constructor parameter
  // You no longer need to pass it in manually.

  // The constructor can now be a default one or omitted if no custom logic is needed.
  ProductService(); // Or simply omit the constructor if not needed

  Future<List<Product>> getAllProducts(String token) async {
    // Directly use BaseUrl.api here
    final url = Uri.parse('${BaseUrl.api}/api/vet/products');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      // You might want to include response.body for better error debugging
      throw Exception('Failed to load products: ${response.statusCode} ${response.body}');
    }
  }
}