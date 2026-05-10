import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// AppController - central state management for the entire app
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

    // Start listening to requests and products in real-time
    _initRequestsStream();
    _initProductsStream();

    // Check for expired requests
    checkAndRevertExpiredRequests();
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

  Future<void> _saveFavorites() async {
    final email = authService.currentUserEmail;
    final key = email != null ? 'favorite_ids_$email' : 'favorite_ids';
    await _storage.setStringList(
      key,
      _favoriteProductIds.map((e) => e.toString()).toList(),
    );
  }

  // ==================== Theme ====================
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ==================== Products (Firebase) ====================
  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  void _initProductsStream() {
    _isLoadingProducts = true;
    notifyListeners();

    FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        await _seedProductsFromApi();
      } else {
        _products = snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
        _isLoadingProducts = false;
        notifyListeners();
      }
    }, onError: (e) {
      _isLoadingProducts = false;
      notifyListeners();
    });
  }

  Future<void> _seedProductsFromApi() async {
    try {
      List<Product> apiProducts = await ApiService.fetchProducts();
      final batch = FirebaseFirestore.instance.batch();
      for (var product in apiProducts) {
        final docRef = FirebaseFirestore.instance.collection('products').doc(product.id.toString());
        batch.set(docRef, product.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding products: $e');
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id.toString())
          .set(product.toJson());
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
  }

  Future<void> updateProduct(int id, Product updated) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(id.toString())
          .update(updated.toJson());
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
  }

  /// Restored for compatibility with UI screens
  Future<void> fetchProducts() async {
    // Products are already synced via Stream, but we can re-trigger if needed
    // or just leave it to satisfy the UI calls.
  }

  Future<void> deleteProduct(int id) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(id.toString())
        .delete();
    _favoriteProductIds.remove(id);
    _saveFavorites();
    notifyListeners();
  }

  Future<List<Product>> searchProducts(String query) async {
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .toList();
  }

  // ==================== Favorites ====================
  final List<int> _favoriteProductIds = [];
  List<int> get favoriteProductIds => List.unmodifiable(_favoriteProductIds);

  List<Product> get favoriteProducts =>
      _products.where((p) => _favoriteProductIds.contains(p.id)).toList();

  bool isFavorite(int productId) => _favoriteProductIds.contains(productId);

  void toggleFavorite(int productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    _saveFavorites();
    notifyListeners();
  }

  // ==================== Repair Requests (Firebase) ====================
  final List<RepairRequest> _requests = [];
  List<RepairRequest> get requests => List.unmodifiable(_requests);
  int _nextRequestId = 1;

  List<RepairRequest> get myRequests => _requests
      .where((r) => r.clientEmail == authService.currentUserEmail)
      .toList();

  List<RepairRequest> get allRequests {
    final email = authService.currentUserEmail;
    return _requests
        .where((r) => r.status == 'pending' || r.techEmail == email)
        .toList();
  }

  void _initRequestsStream() {
    FirebaseFirestore.instance.collection('requests').snapshots().listen((snapshot) {
      _requests.clear();
      for (var doc in snapshot.docs) {
        _requests.add(RepairRequest.fromJson(doc.data()));
      }
      if (_requests.isNotEmpty) {
        _nextRequestId = _requests.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      }
      notifyListeners();
    });
  }

  Future<void> createRequest({
    required String device,
    required String category,
    required String description,
    required String location,
    List<String>? imagePaths,
  }) async {
    final id = _nextRequestId++;
    final request = RepairRequest(
      id: id,
      device: device,
      category: category,
      description: description,
      location: location,
      imagePaths: imagePaths ?? [],
      clientEmail: authService.currentUserEmail ?? 'unknown',
    );
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(id.toString())
        .set(request.toJson());
  }

  Future<void> updateRequest(int id, {String? device, String? description, String? location, String? status, RepairRequest? fullRequest}) async {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      Map<String, dynamic> dataToSave;
      if (fullRequest != null) {
        dataToSave = fullRequest.toJson();
      } else {
        dataToSave = {};
        if (device != null) dataToSave['device'] = device;
        if (description != null) dataToSave['description'] = description;
        if (location != null) dataToSave['location'] = location;
        if (status != null) dataToSave['status'] = status;
      }
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(id.toString())
          .update(dataToSave);
    }
  }

  Future<void> deleteRequest(int id) async {
    await FirebaseFirestore.instance.collection('requests').doc(id.toString()).delete();
  }

  Future<void> acceptRequest(int id, String techNotes, int estimatedDays) async {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updatedRequest = _requests[index].copyWith(
        status: 'accepted',
        techNotes: techNotes,
        techEmail: authService.currentUserEmail,
        techName: authService.currentUserName,
        techNationalId: authService.currentUserPhone, // Or use currentUserPhone if that's what we have
        techId: authService.currentUserId,
        acceptedAt: DateTime.now(),
        estimatedDays: estimatedDays,
      );
      await updateRequest(id, fullRequest: updatedRequest);
    }
  }

  Future<void> completeRequest(int id) async {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updatedRequest = _requests[index].copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
      );
      await updateRequest(id, fullRequest: updatedRequest);
    }
  }

  Future<void> cancelTechRequest(int id) async {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _requests[index];
      final reverted = RepairRequest(
        id: req.id, device: req.device, category: req.category, description: req.description,
        location: req.location, status: 'pending', clientEmail: req.clientEmail,
        createdAt: req.createdAt,
      );
      await FirebaseFirestore.instance.collection('requests').doc(id.toString()).set(reverted.toJson());
    }
  }

  void checkAndRevertExpiredRequests() {
    for (var req in _requests) {
      if (req.isExpired) {
        cancelTechRequest(req.id);
      }
    }
  }

  List<RepairRequest> searchRequests(String query) {
    final q = query.toLowerCase();
    return _requests.where((r) =>
        r.device.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.location.toLowerCase().contains(q) ||
        r.status.toLowerCase().contains(q)).toList();
  }

  int get pendingCount => _requests.where((r) => r.status == 'pending').length;
  int get acceptedCount => _requests.where((r) => r.status == 'accepted').length;
  int get doneCount => _requests.where((r) => r.status == 'completed').length;
}
