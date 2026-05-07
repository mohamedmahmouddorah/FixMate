// AuthService - handles local authentication (Register / Login / Forgot Password)
// Users are stored locally in a JSON file for demo purposes
// Can be replaced with Firebase Authentication later
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  // Singleton pattern - single instance throughout the app
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final StorageService _storage = StorageService.instance;

  /// Local user storage: email → {password, name, phone, id, role}
  final Map<String, Map<String, String>> _users = {
    'admin@fixmate.com': {
      'password': '123456',
      'name': 'Mohamed Mahmoud',
      'phone': '01270846364',
      'id': '30501281700557',
      'role': 'admin',
    },
  };

  Future<void> init() async {
    final usersStr = _storage.getString('users_data_v3');
    if (usersStr != null) {
      final Map<String, dynamic> decoded = json.decode(usersStr);
      _users.clear();
      for (var entry in decoded.entries) {
        _users[entry.key] = Map<String, String>.from(entry.value);
      }
    }
    _currentUserEmail = _storage.getString('current_user_email');
  }

  Future<void> _saveData() async {
    await _storage.setString('users_data_v3', json.encode(_users));
    if (_currentUserEmail != null) {
      await _storage.setString('current_user_email', _currentUserEmail!);
    } else {
      await _storage.remove('current_user_email');
    }
  }

  /// Currently logged in user's email
  String? _currentUserEmail;

  /// Get the current user's email
  String? get currentUserEmail => _currentUserEmail;

  /// Get the current user's name
  String? get currentUserName {
    if (_currentUserEmail == null) return null;
    return _users[_currentUserEmail]?['name'];
  }

  /// Get the current user's phone
  String? get currentUserPhone {
    if (_currentUserEmail == null) return null;
    return _users[_currentUserEmail]?['phone'];
  }

  /// Get the current user's ID
  String? get currentUserId {
    if (_currentUserEmail == null) return null;
    return _users[_currentUserEmail]?['id'];
  }

  String? get currentUserRole {
    if (_currentUserEmail == null) return null;
    return _users[_currentUserEmail]?['role'] ?? 'client';
  }

  String? get currentUserBio {
    if (_currentUserEmail == null) return null;
    return _users[_currentUserEmail]?['bio'];
  }

  bool get isAdmin => currentUserRole == 'admin';
  bool get isTechnician => currentUserRole == 'technician';
  bool get isGuest => currentUserEmail == 'guest@fixmate.com';

  /// Check if user is logged in
  bool get isLoggedIn => _currentUserEmail != null;

  /// Get all registered users (for dashboard)
  Map<String, Map<String, String>> get allUsers => Map.unmodifiable(_users);

  /// Register a new user
  /// Returns null on success, or error message string on failure
  String? register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String id,
    String role = 'client',
    String? bio,
  }) {
    if (_users.containsKey(email.toLowerCase())) {
      return 'This email is already registered';
    }
    for (final user in _users.values) {
      if (user['id'] == id) {
        return 'This ID is already registered';
      }
    }

    _users[email.toLowerCase()] = {
      'password': password,
      'name': name,
      'phone': phone,
      'id': id,
      'role': role,
      if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
    };

    _saveData();

    return null; // Success
  }

  /// Login with email and password
  /// Returns null on success, or error message string on failure
  String? login({required String identifier, required String password}) {
    final searchKey = identifier.toLowerCase();
    String? foundEmail;

    if (_users.containsKey(searchKey)) {
      foundEmail = searchKey;
    } else {
      for (final entry in _users.entries) {
        if (entry.value['id'] == searchKey) {
          foundEmail = entry.key;
          break;
        }
      }
    }

    if (foundEmail == null) {
      return 'No account found with this Email or ID';
    }

    if (_users[foundEmail]!['password'] != password) {
      return 'Incorrect password';
    }

    _currentUserEmail = foundEmail;
    _saveData();
    return null; // Success
  }

  /// Logout current user
  void logout() {
    _currentUserEmail = null;
    _saveData();
  }

  /// Reset password (Forgot Password)
  /// Returns null on success, or error message on failure
  String? resetPassword({
    required String identifier,
    required String newPassword,
  }) {
    final searchKey = identifier.toLowerCase();
    String? foundEmail;

    if (_users.containsKey(searchKey)) {
      foundEmail = searchKey;
    } else {
      for (final entry in _users.entries) {
        if (entry.value['id'] == searchKey) {
          foundEmail = entry.key;
          break;
        }
      }
    }

    if (foundEmail == null) {
      return 'No account found with this Email or ID';
    }

    // Update password
    _users[foundEmail]!['password'] = newPassword;
    _saveData();
    return null; // Success
  }

  /// Update user profile
  String? updateProfile({
    required String email,
    String? name,
    String? phone,
    String? bio,
  }) {
    final userEmail = email.toLowerCase();
    if (!_users.containsKey(userEmail)) {
      return 'User not found';
    }

    if (name != null) _users[userEmail]!['name'] = name;
    if (phone != null) _users[userEmail]!['phone'] = phone;
    if (bio != null) {
      if (bio.trim().isEmpty) {
        _users[userEmail]!.remove('bio');
      } else {
        _users[userEmail]!['bio'] = bio.trim();
      }
    }

    _saveData();
    return null;
  }

  /// Change current user password
  String? changePassword(String newPassword) {
    if (_currentUserEmail == null) return 'Not logged in';
    _users[_currentUserEmail]!['password'] = newPassword;
    _saveData();
    return null;
  }

  // ========== Dashboard CRUD Operations ==========

  /// Add a new user (from dashboard)
  String? addUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String id,
    String role = 'client',
    String? bio,
  }) {
    return register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      id: id,
      role: role,
      bio: bio,
    );
  }

  /// Update an existing user (from dashboard)
  String? updateUser({
    required String email,
    required String name,
    required String phone,
    String? password,
    String? role,
  }) {
    final userEmail = email.toLowerCase();
    if (!_users.containsKey(userEmail)) {
      return 'User not found';
    }

    _users[userEmail]!['name'] = name;
    _users[userEmail]!['phone'] = phone;
    if (role != null) _users[userEmail]!['role'] = role;
    if (password != null && password.isNotEmpty) {
      _users[userEmail]!['password'] = password;
    }

    _saveData();
    return null;
  }

  /// Delete a user (from dashboard)
  String? deleteUser(String email) {
    final userEmail = email.toLowerCase();
    if (!_users.containsKey(userEmail)) {
      return 'User not found';
    }

    _users.remove(userEmail);
    if (userEmail == _currentUserEmail) {
      _currentUserEmail = null;
    }
    _saveData();
    return null;
  }
}
