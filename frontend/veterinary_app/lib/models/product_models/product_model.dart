class Product {
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final int quantity;

  Product({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: (json['nomProduit'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['available'] as int? ?? 0,
    );
  }
}
