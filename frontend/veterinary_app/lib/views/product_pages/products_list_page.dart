import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/utils/logout_helper.dart';
import 'package:veterinary_app/views/components/home_navbar.dart';
import 'package:veterinary_app/views/product_pages/full_screen_image_page.dart';

import 'package:flutter/material.dart';
import 'package:veterinary_app/models/product_models/product_model.dart';
import 'package:veterinary_app/services/product_services/product_service.dart';
import 'package:veterinary_app/utils/app_colors.dart'; // Assuming you have app_colors.dart for kPrimaryGreen

class ProductsListPage extends StatefulWidget {
  final String token;
  final String username;

  const ProductsListPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  late ProductService _productService;
  late Future<List<Product>> _productsFuture;

  final String _baseUrl = '${BaseUrl.api}';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // This will store the current search text, lowercased

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    // Initialize the future with the filtering method
    _productsFuture = _fetchAndFilterProducts();

    // Add listener to search controller to re-filter products
    _searchController.addListener(() {
      print('DEBUG: Search text changed to: "${_searchController.text}"');
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        print('DEBUG: _searchQuery updated to: "$_searchQuery"');
        // Re-assign the future to trigger rebuild and re-filter
        // This is the key step to tell FutureBuilder to re-execute
        _productsFuture = _fetchAndFilterProducts();
        print('DEBUG: _productsFuture re-assigned. UI should rebuild.');
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // New method to fetch and filter products
  Future<List<Product>> _fetchAndFilterProducts() async {
    print('DEBUG: _fetchAndFilterProducts called. Current _searchQuery: "$_searchQuery"');
    try {
      // Always fetch all products first, then filter locally
      final List<Product> allProducts = await _productService.getAllProducts(widget.token);
      print('DEBUG: Fetched ${allProducts.length} total products from service.');

      if (_searchQuery.isEmpty) {
        print('DEBUG: Search query is empty. Returning all ${allProducts.length} products.');
        return allProducts;
      } else {
        // Filter products based on the search query
        final filteredList = allProducts.where((product) {
          final productNameLower = product.name.toLowerCase();
          final productDescriptionLower = product.description.toLowerCase();
          final queryLower = _searchQuery; // already lowercased by listener

          final bool matches = productNameLower.contains(queryLower) ||
              productDescriptionLower.contains(queryLower);
          // Uncomment this print for extremely detailed per-product debugging:
          // print('DEBUG: Checking "${product.name}" for "$queryLower" -> Matches: $matches');
          return matches;
        }).toList();
        print('DEBUG: Filtered products count: ${filteredList.length} for query: "$_searchQuery"');
        return filteredList;
      }
    } catch (e) {
      print('ERROR: Failed to load or filter products: $e');
      // Re-throw the error to be caught by FutureBuilder
      throw Exception('Failed to load or filter products: $e');
    }
  }


  String _buildImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    } else if (imageUrl.startsWith('/')) {
      return '$_baseUrl$imageUrl';
    } else {
      return '$_baseUrl/$imageUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: Column(
        children: [
          // Header/Title for the page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Our Products',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreen,
                  ),
                ),
                Icon(Icons.category, color: kPrimaryGreen, size: 30),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.5, indent: 16, endIndent: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name or description...',
                prefixIcon: const Icon(Icons.search, color: kPrimaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                filled: true,
                fillColor: Colors.white,
              ),
              cursorColor: kPrimaryGreen,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture, // Now calls the filtering method
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('DEBUG: FutureBuilder connectionState: waiting');
                  return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                } else if (snapshot.hasError) {
                  print('DEBUG: FutureBuilder hasError: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 10),
                        Text(
                          'Failed to load products: ${snapshot.error}',
                          style: textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  print('DEBUG: FutureBuilder hasData: ${snapshot.hasData}, data.isEmpty: ${snapshot.data?.isEmpty}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 80),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching products found for "$_searchQuery".'
                              : 'No products found.',
                          style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  final products = snapshot.data!;
                  print('DEBUG: FutureBuilder displaying ${products.length} products.');
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final imageUrl = _buildImageUrl(product.imageUrl);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: kPrimaryGreen.withOpacity(0.3),
                          child: InkWell(
                            onTap: () {
                              // Action when card is tapped (e.g., navigate to product detail)
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'productImage${product.imageUrl}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (imageUrl.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImagePage(
                                                  imageUrl: imageUrl,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                          imageUrl,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 110,
                                              height: 110,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                        )
                                            : Container(
                                          width: 110,
                                          height: 110,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 60,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryGreen,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          product.description,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            '${product.price.toStringAsFixed(2)} DT',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: kAccentGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Return'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}