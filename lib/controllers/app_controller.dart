import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// AppController - central state management for the entire app
/// Uses Singleton pattern so all screens share the same state
/// Implements listener pattern for reactive UI updates
class AppController extends ChangeNotifier {
  // ==================== Singleton ====================
  static final AppController instance = AppController._internal();
  factory AppController() => instance;
  AppController._internal();

  // ==================== Services ====================
  final AuthService authService = AuthService.instance;
  final StorageService _storage = StorageService.instance;

  Future<void> init() async {
    // Load favorites (global or per-user)
    loadFavorites();

    // Load requests
    final reqsStr = _storage.getString('requests_data');
    if (reqsStr != null) {
      try {
        final List<dynamic> decoded = json.decode(reqsStr);
        _requests.clear();
        _requests.addAll(decoded.map((e) => RepairRequest.fromJson(e)));
        if (_requests.isNotEmpty) {
          _nextRequestId = _requests.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      } catch (e) {
        // ignore error
      }
    }
  }

  Future<void> _saveData() async {
    final email = authService.currentUserEmail;
    if (email != null) {
      await _storage.setStringList('favorite_ids_$email', _favoriteProductIds.map((e) => e.toString()).toList());
    } else {
      await _storage.setStringList('favorite_ids', _favoriteProductIds.map((e) => e.toString()).toList());
    }
    await _storage.setString('requests_data', json.encode(_requests.map((r) => r.toJson()).toList()));
    await _storage.setString('products_data', json.encode(_products.map((p) => p.toJson()).toList()));
  }

  void loadFavorites() {
    final email = authService.currentUserEmail;
    final key = email != null ? 'favorite_ids_$email' : 'favorite_ids';
    final favs = _storage.getStringList(key);
    _favoriteProductIds.clear();
    if (favs != null) {
      _favoriteProductIds.addAll(favs.map((e) => int.parse(e)));
    }
    notifyListeners();
  }

  // ==================== Theme ====================
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // ==================== Mode Switch ====================
  bool get isTechnician => authService.isTechnician;
  bool get isAdmin => authService.isAdmin;

  // ==================== Products ====================
  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  String? _productsError;
  String? get productsError => _productsError;

  /// Fetch products from local storage or API
  Future<void> fetchProducts() async {
    if (_products.isNotEmpty) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final productsStr = _storage.getString('products_data');
      if (productsStr != null) {
        final List<dynamic> decoded = json.decode(productsStr);
        _products = decoded.map((e) => Product.fromJson(e)).toList();
        _isLoadingProducts = false;
        notifyListeners();
        return;
      }

      _products = await ApiService.fetchProducts();
      _saveData();

      // Mock requests if completely empty
      if (_requests.isEmpty) {
        final mocks = await ApiService.fetchMockRequests();
        for (var mock in mocks) {
          _requests.add(RepairRequest(
            id: _nextRequestId++,
            device: 'Device ${mock['id']}',
            category: 'General',
            description: mock['body'].toString().replaceAll('\n', ' '),
            location: 'Random Location',
            status: 'pending',
            clientEmail: authService.currentUserEmail ?? 'user@fixmate.com',
          ));
        }
        _saveData();
      }

      _isLoadingProducts = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProducts = false;
      _productsError = e.toString();
      notifyListeners();
    }
  }

  /// Search products from API
  Future<List<Product>> searchProducts(String query) async {
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .toList();
  }

  // ==================== Products CRUD (Local) ====================

  void addProduct(Product product) {
    _products.add(product);
    _saveData();
    notifyListeners();
  }

  void updateProduct(int id, Product updated) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  void deleteProduct(int id) {
    _products.removeWhere((p) => p.id == id);
    // Also remove from favorites if exists
    _favoriteProductIds.remove(id);
    _saveData();
    notifyListeners();
  }

  // ==================== Favorites ====================
  final List<int> _favoriteProductIds = [];
  List<int> get favoriteProductIds => List.unmodifiable(_favoriteProductIds);

  /// Get list of favorite products
  List<Product> get favoriteProducts =>
      _products.where((p) => _favoriteProductIds.contains(p.id)).toList();

  /// Check if a product is in favorites
  bool isFavorite(int productId) => _favoriteProductIds.contains(productId);

  /// Toggle favorite status of a product
  void toggleFavorite(int productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    _saveData();
    notifyListeners();
  }

  // ==================== Repair Requests ====================
  final List<RepairRequest> _requests = [];
  List<RepairRequest> get requests => List.unmodifiable(_requests);

  int _nextRequestId = 1;

  /// Get requests for the current user (client mode)
  List<RepairRequest> get myRequests => _requests
      .where((r) => r.clientEmail == authService.currentUserEmail)
      .toList();

  /// Get all requests (technician mode)
  List<RepairRequest> get allRequests => List.unmodifiable(_requests);

  /// Get requests filtered by status
  List<RepairRequest> getRequestsByStatus(String status) =>
      _requests.where((r) => r.status == status).toList();

  /// Create a new repair request
  void createRequest({
    required String device,
    required String category,
    required String description,
    required String location,
    List<String>? imagePaths,
  }) {
    final request = RepairRequest(
      id: _nextRequestId++,
      device: device,
      category: category,
      description: description,
      location: location,
      imagePaths: imagePaths ?? [],
      clientEmail: authService.currentUserEmail ?? 'unknown',
    );
    _requests.add(request);
    _saveData();
    notifyListeners();
  }

  /// Update an existing request
  void updateRequest(int id, {String? device, String? description, String? location, String? status}) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final request = _requests[index];
      if (device != null) request.device = device;
      if (description != null) request.description = description;
      if (location != null) request.location = location;
      if (status != null) request.status = status;
      _saveData();
      notifyListeners();
    }
  }

  /// Delete a request
  void deleteRequest(int id) {
    _requests.removeWhere((r) => r.id == id);
    _saveData();
    notifyListeners();
  }

  /// Accept a request (Technician action)
  void acceptRequest(int id, String techNotes) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: 'accepted', techNotes: techNotes);
      _saveData();
      notifyListeners();
    }
  }

  /// Mark a request as completed (Technician action)
  void completeRequest(int id) {
    updateRequest(id, status: 'completed');
  }

  // ==================== Search Requests ====================
  List<RepairRequest> searchRequests(String query) {
    final q = query.toLowerCase();
    return _requests
        .where((r) =>
            r.device.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.location.toLowerCase().contains(q) ||
            r.status.toLowerCase().contains(q))
        .toList();
  }

  // Request Stats
  int get pendingCount => _requests.where((r) => r.status == 'pending').length;
  int get acceptedCount => _requests.where((r) => r.status == 'accepted').length;
  int get doneCount => _requests.where((r) => r.status == 'completed').length;
}
