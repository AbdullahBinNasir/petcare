import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  
  // Check if user is fully authenticated (has both Firebase user and user model)
  bool get isFullyAuthenticated => currentUser != null && _currentUserModel != null;
  
  // Check if user is partially authenticated (has Firebase user but no user model yet)
  bool get isPartiallyAuthenticated => currentUser != null && _currentUserModel == null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // Initialize loading state
    _isLoading = true;
  }

  void _onAuthStateChanged(User? user) async {
    try {
      debugPrint('Auth state changed. User: ${user?.uid}');
      _isLoading = true;
      notifyListeners();
      
      if (user != null) {
        await _loadUserModel(user.uid);
      } else {
        _currentUserModel = null;
      }
    } catch (e) {
      debugPrint('Error in auth state change: $e');
      _currentUserModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      debugPrint('Loading user model for UID: $uid');
      
      // Add timeout to prevent infinite loading
      final doc = await _firestore.collection('users').doc(uid).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading user data');
        },
      );
      
      if (doc.exists) {
        debugPrint('User document found, parsing...');
        _currentUserModel = UserModel.fromFirestore(doc);
        debugPrint('User model loaded successfully: ${_currentUserModel?.firstName} ${_currentUserModel?.lastName}');
      } else {
        debugPrint('❌ User document not found for UID: $uid');
        debugPrint('❌ This means the user was created in Firebase Auth but not in Firestore');
        _currentUserModel = null;
      }
    } catch (e) {
      debugPrint('❌ Error loading user model: $e');
      _currentUserModel = null;
    }
  }

  // Register new user
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? phoneNumber,
    String? clinicName,
    String? licenseNumber,
    String? shelterName,
    String? address,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          clinicName: clinicName,
          licenseNumber: licenseNumber,
          shelterName: shelterName,
          address: address,
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toFirestore());

        _currentUserModel = userModel;
        return null; // Success
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return 'Registration failed';
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      return 'An unexpected error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }

  // Manually refresh authentication state
  Future<void> refreshAuthState() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserModel(user.uid);
      } else {
        _currentUserModel = null;
      }
    } catch (e) {
      debugPrint('Error refreshing auth state: $e');
      _currentUserModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<String?> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.copyWith(updatedAt: DateTime.now()).toFirestore());
      
      _currentUserModel = updatedUser.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Failed to update profile';
    }
  }

  // Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to change password';
    }
  }
}
