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

  bool _isOnboardingComplete = false;
  bool get isOnboardingComplete => _isOnboardingComplete;

  Future<void> init() async {
    // Load onboarding status
    _isOnboardingComplete = _storage.getBool('onboarding_complete') ?? false;

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
          _nextRequestId =
              _requests.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      } catch (e) {
        // ignore error
      }
    }

    // Load locally added and deleted products
    _loadLocalProductChanges();

    // Check for expired requests
    checkAndRevertExpiredRequests();
  }

  // Lists to track local changes to API data
  List<Product> _locallyAddedProducts = [];
  List<int> _locallyDeletedProductIds = [];

  void _loadLocalProductChanges() {
    final addedStr = _storage.getString('locally_added_products');
    if (addedStr != null) {
      final List<dynamic> decoded = json.decode(addedStr);
      _locallyAddedProducts = decoded.map((e) => Product.fromJson(e)).toList();
    }

    final deletedStr = _storage.getStringList('locally_deleted_ids');
    if (deletedStr != null) {
      _locallyDeletedProductIds = deletedStr.map((e) => int.parse(e)).toList();
    }
  }

  Future<void> _saveLocalProductChanges() async {
    await _storage.setString(
      'locally_added_products',
      json.encode(_locallyAddedProducts.map((p) => p.toJson()).toList()),
    );
    await _storage.setStringList(
      'locally_deleted_ids',
      _locallyDeletedProductIds.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _saveData() async {
    final email = authService.currentUserEmail;
    if (email != null) {
      await _storage.setStringList(
        'favorite_ids_$email',
        _favoriteProductIds.map((e) => e.toString()).toList(),
      );
    } else {
      await _storage.setStringList(
        'favorite_ids',
        _favoriteProductIds.map((e) => e.toString()).toList(),
      );
    }
    await _storage.setString(
      'requests_data',
      json.encode(_requests.map((r) => r.toJson()).toList()),
    );
    await _storage.setString(
      'products_data_v8',
      json.encode(_products.map((p) => p.toJson()).toList()),
    );
  }

  void completeOnboarding() {
    _isOnboardingComplete = true;
    _storage.setBool('onboarding_complete', true);
    notifyListeners();
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

  /// Fetch products from API (Priority) and merge with local changes
  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      // 1. Fetch fresh data from API
      List<Product> apiProducts = await ApiService.fetchProducts();

      // 2. Filter out products that were locally deleted
      apiProducts.removeWhere((p) => _locallyDeletedProductIds.contains(p.id));

      // 3. Combine with locally added products
      _products = [...apiProducts, ..._locallyAddedProducts];

      // 4. Update storage with a cache version for offline use
      _storage.setString(
        'products_data_cache',
        json.encode(_products.map((p) => p.toJson()).toList()),
      );

      _isLoadingProducts = false;
      notifyListeners();
    } catch (e) {
      // If API fails (offline), try to load from cache
      final cachedStr = _storage.getString('products_data_cache');
      if (cachedStr != null) {
        final List<dynamic> decoded = json.decode(cachedStr);
        _products = decoded.map((e) => Product.fromJson(e)).toList();
        _isLoadingProducts = false;
        notifyListeners();
      } else {
        _isLoadingProducts = false;
        _productsError = 'Offline and no cached data available.';
        notifyListeners();
      }
    }
  }

  /// Search products from API
  Future<List<Product>> searchProducts(String query) async {
    final q = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q),
        )
        .toList();
  }

  // ==================== Products CRUD (Local) ====================

  void addProduct(Product product) {
    _locallyAddedProducts.add(product);
    _products.add(product);
    _saveLocalProductChanges();
    notifyListeners();
  }

  void updateProduct(int id, Product updated) {
    // Update in main list
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = updated;
    }

    // Update in locally added list if it exists there
    final localIndex = _locallyAddedProducts.indexWhere((p) => p.id == id);
    if (localIndex != -1) {
      _locallyAddedProducts[localIndex] = updated;
      _saveLocalProductChanges();
    }
    notifyListeners();
  }

  void deleteProduct(int id) {
    // If it's a locally added product, just remove it from that list
    _locallyAddedProducts.removeWhere((p) => p.id == id);

    // If it's an API product, track its ID in deleted list
    if (!_locallyDeletedProductIds.contains(id)) {
      _locallyDeletedProductIds.add(id);
    }

    _products.removeWhere((p) => p.id == id);
    _favoriteProductIds.remove(id);

    _saveLocalProductChanges();
    _saveData(); // for favorites
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
  /// Shows 'pending' requests (available for anyone) OR requests assigned to the current tech
  List<RepairRequest> get allRequests {
    final email = authService.currentUserEmail;
    return _requests
        .where((r) => r.status == 'pending' || r.techEmail == email)
        .toList();
  }

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
  void updateRequest(
    int id, {
    String? device,
    String? description,
    String? location,
    String? status,
  }) {
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
  void acceptRequest(int id, String techNotes, int estimatedDays) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        status: 'accepted',
        techNotes: techNotes,
        techEmail: authService.currentUserEmail,
        acceptedAt: DateTime.now(),
        estimatedDays: estimatedDays,
      );
      _saveData();
      notifyListeners();
    }
  }

  /// Mark a request as completed (Technician action)
  void completeRequest(int id) {
    updateRequest(id, status: 'completed');
  }

  /// Cancel an accepted request (Technician action)
  void cancelTechRequest(int id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _requests[index];
      _requests[index] = RepairRequest(
        id: req.id,
        device: req.device,
        category: req.category,
        description: req.description,
        location: req.location,
        status: 'pending',
        clientEmail: req.clientEmail,
        techEmail: null,
        techNotes: null,
        imagePaths: req.imagePaths,
        createdAt: req.createdAt,
        acceptedAt: null,
        estimatedDays: null,
      );
      _saveData();
      notifyListeners();
    }
  }

  /// Automatically revert requests to pending if they exceed the estimated time
  void checkAndRevertExpiredRequests() {
    bool changed = false;
    for (int i = 0; i < _requests.length; i++) {
      if (_requests[i].isExpired) {
        final req = _requests[i];
        _requests[i] = RepairRequest(
          id: req.id,
          device: req.device,
          category: req.category,
          description: req.description,
          location: req.location,
          status: 'pending',
          clientEmail: req.clientEmail,
          techEmail: null,
          techNotes: null,
          imagePaths: req.imagePaths,
          createdAt: req.createdAt,
          acceptedAt: null,
          estimatedDays: null,
        );
        changed = true;
      }
    }
    if (changed) {
      _saveData();
      notifyListeners();
    }
  }

  // ==================== Search Requests ====================
  List<RepairRequest> searchRequests(String query) {
    final q = query.toLowerCase();
    return _requests
        .where(
          (r) =>
              r.device.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              r.location.toLowerCase().contains(q) ||
              r.status.toLowerCase().contains(q),
        )
        .toList();
  }

  // Request Stats
  int get pendingCount => _requests.where((r) => r.status == 'pending').length;
  int get acceptedCount =>
      _requests.where((r) => r.status == 'accepted').length;
  int get doneCount => _requests.where((r) => r.status == 'completed').length;
}
