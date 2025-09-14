import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/pet_model.dart';

class PetService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get pets by owner ID
Future<List<PetModel>> getPetsByOwnerId(String ownerId) async {
  try {
    print('Fetching pets for owner ID: $ownerId');
    
    // Get all pets for the owner first, then filter in code to handle null isActive values
    final querySnapshot = await _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    print('Found ${querySnapshot.docs.length} pets in Firestore');

    final pets = querySnapshot.docs.map((doc) {
      try {
        print('Processing pet document: ${doc.id}');
        final pet = PetModel.fromFirestore(doc);
        // Filter out inactive pets (isActive == false or null)
        return pet.isActive ? pet : null;
      } catch (e) {
        print('Error processing pet ${doc.id}: $e');
        return null;
      }
    }).where((pet) => pet != null).cast<PetModel>().toList();

    // Sort manually in code instead of Firestore
    pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    print('Successfully parsed ${pets.length} active pets');
    return pets;
  } catch (e) {
    print('Error getting pets: $e');
    print('Stack trace: ${StackTrace.current}');
    return [];
  }
}

  // Get pet by ID
  Future<PetModel?> getPetById(String petId) async {
    try {
      print('Fetching pet with ID: $petId');
      final doc = await _firestore.collection('pets').doc(petId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Pet found: ${doc.data()}');
        return PetModel.fromFirestore(doc);
      } else {
        print('Pet not found or has no data');
      }
    } catch (e) {
      print('Error getting pet: $e');
    }
    return null;
  }

  // Add new pet
  Future<String?> addPet(PetModel pet) async {
    try {
      print('Adding new pet: ${pet.name}');
      print('Pet data to save: ${pet.toFirestore()}');
      
      final docRef = await _firestore.collection('pets').add(pet.toFirestore());
      print('Pet added successfully with ID: ${docRef.id}');
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding pet: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update pet
  Future<bool> updatePet(PetModel pet) async {
    try {
      print('Updating pet: ${pet.id} - ${pet.name}');
      
      final updatedPet = pet.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('pets')
          .doc(pet.id)
          .update(updatedPet.toFirestore());
      
      print('Pet updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }

  // Delete pet (soft delete)
  Future<bool> deletePet(String petId) async {
    try {
      print('Soft deleting pet: $petId');
      
      await _firestore.collection('pets').doc(petId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Pet deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }

  // Upload pet photo
  Future<String?> uploadPetPhoto(File imageFile, String petId) async {
    try {
      print('Uploading photo for pet: $petId');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('pet_photos/$petId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // Add photo URL to pet
  Future<bool> addPhotoToPet(String petId, String photoUrl) async {
    try {
      print('Adding photo URL to pet: $petId');
      
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (!petDoc.exists) {
        print('Pet not found');
        return false;
      }
      
      final pet = PetModel.fromFirestore(petDoc);
      final updatedPhotoUrls = List<String>.from(pet.photoUrls)..add(photoUrl);
      
      await _firestore.collection('pets').doc(petId).update({
        'photoUrls': updatedPhotoUrls,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Photo URL added successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding photo URL to pet: $e');
      return false;
    }
  }

  // Search pets by name, breed, or species
  Future<List<PetModel>> searchPets({
    required String query,
    String? ownerId,
  }) async {
    try {
      print('Searching pets with query: $query');
      
      Query baseQuery = _firestore.collection('pets');
      
      if (ownerId != null) {
        baseQuery = baseQuery.where('ownerId', isEqualTo: ownerId);
      }

      final querySnapshot = await baseQuery.get();

      final pets = querySnapshot.docs
          .map((doc) {
            try {
              final pet = PetModel.fromFirestore(doc);
              // Filter out inactive pets (isActive == false or null)
              return pet.isActive ? pet : null;
            } catch (e) {
              print('Error parsing pet in search: $e');
              return null;
            }
          })
          .where((pet) => pet != null)
          .cast<PetModel>()
          .toList();

      // Filter by search query
      final filteredPets = pets.where((pet) {
        final searchText = query.toLowerCase();
        return pet.name.toLowerCase().contains(searchText) ||
               pet.breed.toLowerCase().contains(searchText) ||
               pet.species.toString().toLowerCase().contains(searchText);
      }).toList();

      print('Found ${filteredPets.length} pets matching search');
      return filteredPets;
    } catch (e) {
      print('Error searching pets: $e');
      return [];
    }
  }

  // Get pets by species
  Future<List<PetModel>> getPetsBySpecies(PetSpecies species, {String? ownerId}) async {
    try {
      print('Fetching pets by species: $species');
      
      Query query = _firestore
          .collection('pets')
          .where('species', isEqualTo: species.toString().split('.').last);
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final querySnapshot = await query.get();

      final pets = querySnapshot.docs
          .map((doc) {
            try {
              final pet = PetModel.fromFirestore(doc);
              // Filter out inactive pets (isActive == false or null)
              return pet.isActive ? pet : null;
            } catch (e) {
              print('Error parsing pet by species: $e');
              return null;
            }
          })
          .where((pet) => pet != null)
          .cast<PetModel>()
          .toList();

      print('Found ${pets.length} pets of species $species');
      return pets;
    } catch (e) {
      print('Error getting pets by species: $e');
      return [];
    }
  }

  // Get pets by health status
  Future<List<PetModel>> getPetsByHealthStatus(HealthStatus status, {String? ownerId}) async {
    try {
      print('Fetching pets by health status: $status');
      
      Query query = _firestore
          .collection('pets')
          .where('healthStatus', isEqualTo: status.toString().split('.').last);
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final querySnapshot = await query.get();

      final pets = querySnapshot.docs
          .map((doc) {
            try {
              final pet = PetModel.fromFirestore(doc);
              // Filter out inactive pets (isActive == false or null)
              return pet.isActive ? pet : null;
            } catch (e) {
              print('Error parsing pet by health status: $e');
              return null;
            }
          })
          .where((pet) => pet != null)
          .cast<PetModel>()
          .toList();

      print('Found ${pets.length} pets with health status $status');
      return pets;
    } catch (e) {
      print('Error getting pets by health status: $e');
      return [];
    }
  }

  // Stream pets by owner ID (real-time updates)
  Stream<List<PetModel>> streamPetsByOwnerId(String ownerId) {
    print('Setting up stream for pets of owner: $ownerId');
    
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Stream received ${snapshot.docs.length} pets');
          
          return snapshot.docs
              .map((doc) {
                try {
                  final pet = PetModel.fromFirestore(doc);
                  // Filter out inactive pets (isActive == false or null)
                  return pet.isActive ? pet : null;
                } catch (e) {
                  print('Error parsing pet in stream: $e');
                  return null;
                }
              })
              .where((pet) => pet != null)
              .cast<PetModel>()
              .toList();
        });
  }

  // Check if pet name exists for owner (to prevent duplicates)
  Future<bool> petNameExists(String name, String ownerId, {String? excludePetId}) async {
    try {
      Query query = _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: ownerId)
          .where('name', isEqualTo: name);

      final querySnapshot = await query.get();
      
      // Filter for active pets only
      final activePets = querySnapshot.docs.where((doc) {
        try {
          final pet = PetModel.fromFirestore(doc);
          return pet.isActive;
        } catch (e) {
          return false;
        }
      });
      
      if (excludePetId != null) {
        return activePets.any((doc) => doc.id != excludePetId);
      }
      
      return activePets.isNotEmpty;
    } catch (e) {
      print('Error checking pet name existence: $e');
      return false;
    }
  }
}