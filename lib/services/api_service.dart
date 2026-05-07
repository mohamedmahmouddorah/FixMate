import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

/// ApiService - handles all HTTP requests to external APIs
/// Uses dummyjson.com for product/device data
class ApiService {
  // Base URL for products API
  static const String _productsBaseUrl = 'https://dummyjson.com/products';

  /// Fetch all products (devices) from dummyjson.com
  /// We fetch smartphones and laptops to simulate devices
  static Future<List<Product>> fetchProducts() async {
    try {
      final res1 = await http.get(
        Uri.parse('$_productsBaseUrl/category/smartphones?limit=10'),
      );
      final res2 = await http.get(
        Uri.parse('$_productsBaseUrl/category/laptops?limit=10'),
      );

      List<Product> allDevices = [];

      if (res1.statusCode == 200) {
        final data = json.decode(res1.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        allDevices.addAll(productsJson.map((json) {
          final p = Product.fromJson(json);
          return p.copyWith(category: 'Phones');
        }));
      }

      if (res2.statusCode == 200) {
        final data = json.decode(res2.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        allDevices.addAll(productsJson.map((json) {
          final p = Product.fromJson(json);
          return p.copyWith(category: 'Laptops');
        }));
      }

      // Add Mock Home Appliances with stable high-quality images
      allDevices.addAll([
        Product(
          id: 1001,
          title: 'Samsung Family Hub',
          description: 'Smart refrigerator with touch screen and internal cameras.',
          price: 2499,
          discountPercentage: 5,
          rating: 4.8,
          stock: 15,
          brand: 'Samsung',
          category: 'Refrigerators',
          thumbnail: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400',
          images: [],
          tags: [],
        ),
        Product(
          id: 1002,
          title: 'LG ThinQ Washer',
          description: 'Front load washing machine with AI technology.',
          price: 899,
          discountPercentage: 10,
          rating: 4.6,
          stock: 20,
          brand: 'LG',
          category: 'Washing Machines',
          thumbnail: 'https://images.unsplash.com/photo-1626806819282-2c1dc01a5e0c?auto=format&fit=crop&q=80&w=400',
          images: [],
          tags: [],
        ),
        Product(
          id: 1004,
          title: 'Whirlpool Refrigerator',
          description: 'Double door refrigerator with frost-free technology.',
          price: 1200,
          discountPercentage: 8,
          rating: 4.7,
          stock: 12,
          brand: 'Whirlpool',
          category: 'Refrigerators',
          thumbnail: 'https://images.unsplash.com/photo-1571175432290-ef71a58da9bc?auto=format&fit=crop&q=80&w=400',
          images: [],
          tags: [],
        ),
      ]);

      if (allDevices.isEmpty) {
        throw Exception('Failed to load products');
      }

      return allDevices;
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Fetch mock requests from jsonplaceholder
  static Future<List<Map<String, dynamic>>> fetchMockRequests() async {
    try {
      final res = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=5'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search products by query string
  /// Uses the dummyjson.com search endpoint
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_productsBaseUrl/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  /// Fetch a single product by its ID
  static Future<Product> fetchProductById(int id) async {
    try {
      final response = await http.get(Uri.parse('$_productsBaseUrl/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  /// Fetch products by category
  static Future<List<Product>> fetchProductsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$_productsBaseUrl/category/$category'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category: $e');
    }
  }
}
