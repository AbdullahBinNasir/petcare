import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  // Get all veterinarians
  Future<List<UserModel>> getVeterinarians() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'veterinarian')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting veterinarians: $e');
      return [];
    }
  }

  // Get all shelter admins
  Future<List<UserModel>> getShelterAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'shelterAdmin')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting shelter admins: $e');
      return [];
    }
  }

  // Search users by name or clinic/shelter name
  Future<List<UserModel>> searchUsers({
    required String query,
    UserRole? role,
  }) async {
    try {
      Query baseQuery = _firestore.collection('users');
      
      if (role != null) {
        baseQuery = baseQuery.where('role', isEqualTo: role.toString().split('.').last);
      }

      final querySnapshot = await baseQuery
          .where('isActive', isEqualTo: true)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Filter by search query
      return users.where((user) {
        final searchText = query.toLowerCase();
        return user.fullName.toLowerCase().contains(searchText) ||
               (user.clinicName?.toLowerCase().contains(searchText) ?? false) ||
               (user.shelterName?.toLowerCase().contains(searchText) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Update user profile
  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Deactivate user account
  Future<bool> deactivateUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'isActive': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      return true;
    } catch (e) {
      print('Error deactivating user: $e');
      return false;
    }
  }
}
