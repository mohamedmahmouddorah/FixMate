import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';

class AuthService {
  // Singleton pattern
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache for user metadata to avoid constant Firestore reads
  Map<String, dynamic>? _currentUserData;

  Future<void> init() async {
    // Listen to auth changes and fetch user data from Firestore
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        _currentUserData = doc.data();
      } else {
        _currentUserData = null;
      }
    });

    // Initial check if already logged in
    if (_auth.currentUser != null) {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      _currentUserData = doc.data();
    }
  }

  /// Get the current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Get the current user's uid
  String? get currentUid => _auth.currentUser?.uid;

  /// Get the current user's name from cache
  String? get currentUserName => _currentUserData?['name'];

  /// Get the current user's phone from cache
  String? get currentUserPhone => _currentUserData?['phone'];

  /// Get the current user's ID card number from cache
  String? get currentUserId => _currentUserData?['id'];

  /// Get the current user's role from cache
  String? get currentUserRole => _currentUserData?['role'] ?? 'client';

  /// Get the current user's bio
  String? get currentUserBio => _currentUserData?['bio'];

  /// Get the current user's image path
  String? get currentUserImage => _currentUserData?['imagePath'];

  bool get isAdmin => currentUserRole == 'admin';
  bool get isTechnician => currentUserRole == 'technician';
  bool get isGuest => currentUserEmail == 'guest@fixmate.com';

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Register a new user with Firebase
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String id,
    String role = 'client',
    String? bio,
    String? imagePath,
  }) async {
    try {
      // 1. Check if ID already exists in Firestore
      final idQuery = await _firestore
          .collection('users')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (idQuery.docs.isNotEmpty) {
        return 'This ID number is already registered with another account';
      }

      // 2. Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Store extra details in Firestore
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'id': id,
        'role': (email == 'admin@fixmate.com') ? 'admin' : role,
        'bio': bio,
        'imagePath': imagePath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);
      _currentUserData = userData;

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// Login with Firebase
  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier.trim();
      
      // If identifier is not email (like ID), find email in Firestore
      if (!identifier.contains('@')) {
        final query = await _firestore
            .collection('users')
            .where('id', isEqualTo: identifier)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) return 'No user found with this ID number';
        email = query.docs.first.get('email');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Fetch full profile from Firestore
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (doc.exists) {
          _currentUserData = doc.data();
          _currentUserData!['uid'] = userCredential.user!.uid;
          
          // Save to local storage for persistence
          await StorageService.instance.setMap('current_user', _currentUserData!);
          return null; // Success
        } else {
          return 'User profile not found in database';
        }
      }
      return 'Authentication failed';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No account found with this email';
      if (e.code == 'wrong-password') return 'Incorrect password';
      return e.message;
    } catch (e) {
      return 'Connection error: ${e.toString()}';
    }
  }

  /// Logout from Firebase
  Future<void> logout() async {
    await _auth.signOut();
    _currentUserData = null;
  }

  /// Reset password (Firebase Auth handles this via email)
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Update profile in Firestore
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Not logged in';

      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      
      if (removeImage) {
        updates['imagePath'] = FieldValue.delete();
      } else if (imagePath != null) {
        updates['imagePath'] = imagePath;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        
        // Update local cache carefully
        final Map<String, dynamic> localUpdates = Map.from(updates);
        if (removeImage) {
          localUpdates['imagePath'] = null; // Use null for local UI, not FieldValue
        }
        _currentUserData?.addAll(localUpdates);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Get user details by email (Search Firestore)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  /// Get all users (for Admin Dashboard)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  /// Change current user password
  Future<String?> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ========== Dashboard CRUD Operations ==========

  /// Add a new user (from dashboard)
  Future<String?> addUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String id,
    String role = 'client',
    String? bio,
  }) async {
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
  Future<String?> updateUser({
    required String uid,
    required String name,
    required String phone,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'name': name,
        'phone': phone,
      };
      if (role != null) updates['role'] = role;

      await _firestore.collection('users').doc(uid).update(updates);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Reset password via email
  Future<String?> resetPassword({required String identifier}) async {
    // If identifier is an ID, find the email first
    String emailToUse = identifier;
    if (!identifier.contains('@')) {
      final query = await _firestore
          .collection('users')
          .where('id', isEqualTo: identifier)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return 'No account found with this ID';
      emailToUse = query.docs.first.get('email');
    }
    
    try {
      await _auth.sendPasswordResetEmail(email: emailToUse);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Delete a user (Admin only)
  Future<String?> deleteUser(String uid) async {
    try {
      // Note: This only deletes the Firestore record. 
      // Deleting the actual Auth account requires Firebase Admin SDK or Cloud Functions.
      await _firestore.collection('users').doc(uid).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
