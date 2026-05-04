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
      final res1 = await http.get(Uri.parse('$_productsBaseUrl/category/smartphones?limit=10'));
      final res2 = await http.get(Uri.parse('$_productsBaseUrl/category/laptops?limit=10'));

      List<Product> allDevices = [];

      if (res1.statusCode == 200) {
        final data = json.decode(res1.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        allDevices.addAll(productsJson.map((json) => Product.fromJson(json)));
      }

      if (res2.statusCode == 200) {
        final data = json.decode(res2.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        allDevices.addAll(productsJson.map((json) => Product.fromJson(json)));
      }

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
      final res = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=5'));
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
      final response = await http.get(
        Uri.parse('$_productsBaseUrl/$id'),
      );

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
