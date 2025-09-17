import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/pet_listing_model.dart';

class PetListingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get pet listings by shelter owner ID
  Future<List<PetListingModel>> getPetListingsByShelterOwnerId(String shelterOwnerId) async {
    try {
      print('Fetching pet listings for shelter owner ID: $shelterOwnerId');
      
      final querySnapshot = await _firestore
          .collection('pet_listings')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} pet listings in Firestore');

      final petListings = querySnapshot.docs.map((doc) {
        try {
          print('Processing pet listing document: ${doc.id}');
          return PetListingModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing pet listing ${doc.id}: $e');
          return null;
        }
      }).where((listing) => listing != null).cast<PetListingModel>().toList();

      // Sort manually in code instead of Firestore
      petListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${petListings.length} pet listings');
      return petListings;
    } catch (e) {
      print('Error getting pet listings: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get pet listing by ID
  Future<PetListingModel?> getPetListingById(String listingId) async {
    try {
      print('Fetching pet listing with ID: $listingId');
      final doc = await _firestore.collection('pet_listings').doc(listingId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Pet listing found: ${doc.data()}');
        return PetListingModel.fromFirestore(doc);
      } else {
        print('Pet listing not found or has no data');
      }
    } catch (e) {
      print('Error getting pet listing: $e');
    }
    return null;
  }

  // Add new pet listing
  Future<String?> addPetListing(PetListingModel petListing) async {
    try {
      print('Adding new pet listing: ${petListing.name}');
      print('Pet listing data to save: ${petListing.toFirestore()}');
      
      final docRef = await _firestore.collection('pet_listings').add(petListing.toFirestore());
      print('Pet listing added successfully with ID: ${docRef.id}');
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding pet listing: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update pet listing
  Future<bool> updatePetListing(PetListingModel petListing) async {
    try {
      print('Updating pet listing: ${petListing.id} - ${petListing.name}');
      
      final updatedListing = petListing.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('pet_listings')
          .doc(petListing.id)
          .update(updatedListing.toFirestore());
      
      print('Pet listing updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating pet listing: $e');
      return false;
    }
  }

  // Delete pet listing (soft delete)
  Future<bool> deletePetListing(String listingId) async {
    try {
      print('Soft deleting pet listing: $listingId');
      
      await _firestore.collection('pet_listings').doc(listingId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Pet listing deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting pet listing: $e');
      return false;
    }
  }

  // Upload pet listing photo
  Future<String?> uploadPetListingPhoto(File imageFile, String listingId) async {
    try {
      print('Uploading photo for pet listing: $listingId');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('pet_listing_photos/$listingId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // Upload pet listing photo from XFile (for web compatibility)
  Future<String?> uploadPetListingPhotoFromXFile(XFile xFile, String listingId) async {
    try {
      print('Uploading photo from XFile for pet listing: $listingId');
      
      // Converts XFile to base64 data URL
      final bytes = await xFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = xFile.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      print('Photo converted to base64 data URL successfully');
      return dataUrl; // Returns base64 data URL
    } catch (e) {
      print('Error uploading photo from XFile: $e');
      return null;
    }
  }

  // Add photo URL to pet listing
  Future<bool> addPhotoToPetListing(String listingId, String photoUrl) async {
    try {
      print('Adding photo URL to pet listing: $listingId');
      
      final listingDoc = await _firestore.collection('pet_listings').doc(listingId).get();
      if (!listingDoc.exists) {
        print('Pet listing not found');
        return false;
      }
      
      final listing = PetListingModel.fromFirestore(listingDoc);
      final updatedPhotoUrls = List<String>.from(listing.photoUrls)..add(photoUrl);
      
      await _firestore.collection('pet_listings').doc(listingId).update({
        'photoUrls': updatedPhotoUrls,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Photo URL added successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding photo URL to pet listing: $e');
      return false;
    }
  }

  // Search pet listings by name, breed, or type
  Future<List<PetListingModel>> searchPetListings({
    required String query,
    String? shelterOwnerId,
    PetListingType? type,
    PetListingStatus? status,
  }) async {
    try {
      print('Searching pet listings with query: $query');
      
      Query baseQuery = _firestore.collection('pet_listings');
      
      if (shelterOwnerId != null) {
        baseQuery = baseQuery.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      if (type != null) {
        baseQuery = baseQuery.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (status != null) {
        baseQuery = baseQuery.where('status', isEqualTo: status.toString().split('.').last);
      }

      final querySnapshot = await baseQuery
          .where('isActive', isEqualTo: true)
          .get();

      final petListings = querySnapshot.docs
          .map((doc) {
            try {
              return PetListingModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing pet listing in search: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<PetListingModel>()
          .toList();

      // Filter by search query
      final filteredListings = petListings.where((listing) {
        final searchText = query.toLowerCase();
        return listing.name.toLowerCase().contains(searchText) ||
               listing.breed.toLowerCase().contains(searchText) ||
               listing.type.toString().toLowerCase().contains(searchText) ||
               (listing.description?.toLowerCase().contains(searchText) ?? false);
      }).toList();

      print('Found ${filteredListings.length} pet listings matching search');
      return filteredListings;
    } catch (e) {
      print('Error searching pet listings: $e');
      return [];
    }
  }

  // Get pet listings by type
  Future<List<PetListingModel>> getPetListingsByType(PetListingType type, {String? shelterOwnerId}) async {
    try {
      print('Fetching pet listings by type: $type');
      
      Query query = _firestore
          .collection('pet_listings')
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final petListings = querySnapshot.docs
          .map((doc) {
            try {
              return PetListingModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing pet listing by type: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<PetListingModel>()
          .toList();

      print('Found ${petListings.length} pet listings of type $type');
      return petListings;
    } catch (e) {
      print('Error getting pet listings by type: $e');
      return [];
    }
  }

  // Get pet listings by status
  Future<List<PetListingModel>> getPetListingsByStatus(PetListingStatus status, {String? shelterOwnerId}) async {
    try {
      print('Fetching pet listings by status: $status');
      
      Query query = _firestore
          .collection('pet_listings')
          .where('status', isEqualTo: status.toString().split('.').last)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final petListings = querySnapshot.docs
          .map((doc) {
            try {
              return PetListingModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing pet listing by status: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<PetListingModel>()
          .toList();

      print('Found ${petListings.length} pet listings with status $status');
      return petListings;
    } catch (e) {
      print('Error getting pet listings by status: $e');
      return [];
    }
  }

  // Stream pet listings by shelter owner ID (real-time updates)
  Stream<List<PetListingModel>> streamPetListingsByShelterOwnerId(String shelterOwnerId) {
    print('Setting up stream for pet listings of shelter owner: $shelterOwnerId');
    
    return _firestore
        .collection('pet_listings')
        .where('shelterOwnerId', isEqualTo: shelterOwnerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Stream received ${snapshot.docs.length} pet listings');
          
          return snapshot.docs
              .map((doc) {
                try {
                  return PetListingModel.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing pet listing in stream: $e');
                  return null;
                }
              })
              .where((listing) => listing != null)
              .cast<PetListingModel>()
              .toList();
        });
  }

  // Check if pet listing name exists for shelter owner (to prevent duplicates)
  Future<bool> petListingNameExists(String name, String shelterOwnerId, {String? excludeListingId}) async {
    try {
      Query query = _firestore
          .collection('pet_listings')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true);

      final querySnapshot = await query.get();
      
      if (excludeListingId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeListingId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pet listing name existence: $e');
      return false;
    }
  }

  // Update pet listing status
  Future<bool> updatePetListingStatus(String listingId, PetListingStatus status) async {
    try {
      print('Updating pet listing status: $listingId to $status');
      
      await _firestore.collection('pet_listings').doc(listingId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Pet listing status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating pet listing status: $e');
      return false;
    }
  }
}
