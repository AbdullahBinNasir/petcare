import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adoption_request_model.dart';

class AdoptionRequestService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get adoption requests by shelter owner ID
  Future<List<AdoptionRequestModel>> getAdoptionRequestsByShelterOwnerId(String shelterOwnerId) async {
    try {
      print('Fetching adoption requests for shelter owner ID: $shelterOwnerId');
      
      final querySnapshot = await _firestore
          .collection('adoption_requests')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} adoption requests in Firestore');

      final adoptionRequests = querySnapshot.docs.map((doc) {
        try {
          print('Processing adoption request document: ${doc.id}');
          return AdoptionRequestModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing adoption request ${doc.id}: $e');
          return null;
        }
      }).where((request) => request != null).cast<AdoptionRequestModel>().toList();

      // Sort manually in code instead of Firestore
      adoptionRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${adoptionRequests.length} adoption requests');
      return adoptionRequests;
    } catch (e) {
      print('Error getting adoption requests: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get adoption requests by pet owner ID
  Future<List<AdoptionRequestModel>> getAdoptionRequestsByPetOwnerId(String petOwnerId) async {
    try {
      print('Fetching adoption requests for pet owner ID: $petOwnerId');
      
      final querySnapshot = await _firestore
          .collection('adoption_requests')
          .where('petOwnerId', isEqualTo: petOwnerId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} adoption requests in Firestore');

      final adoptionRequests = querySnapshot.docs.map((doc) {
        try {
          print('Processing adoption request document: ${doc.id}');
          return AdoptionRequestModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing adoption request ${doc.id}: $e');
          return null;
        }
      }).where((request) => request != null).cast<AdoptionRequestModel>().toList();

      // Sort manually in code instead of Firestore
      adoptionRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${adoptionRequests.length} adoption requests');
      return adoptionRequests;
    } catch (e) {
      print('Error getting adoption requests: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get adoption request by ID
  Future<AdoptionRequestModel?> getAdoptionRequestById(String requestId) async {
    try {
      print('Fetching adoption request with ID: $requestId');
      final doc = await _firestore.collection('adoption_requests').doc(requestId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Adoption request found: ${doc.data()}');
        return AdoptionRequestModel.fromFirestore(doc);
      } else {
        print('Adoption request not found or has no data');
      }
    } catch (e) {
      print('Error getting adoption request: $e');
    }
    return null;
  }

  // Add new adoption request
  Future<String?> addAdoptionRequest(AdoptionRequestModel adoptionRequest) async {
    try {
      print('Adding new adoption request for pet: ${adoptionRequest.petName}');
      print('Adoption request data to save: ${adoptionRequest.toFirestore()}');
      
      // Validate required fields
      if (adoptionRequest.petListingId.isEmpty) {
        print('Error: petListingId is empty');
        return null;
      }
      if (adoptionRequest.petOwnerId.isEmpty) {
        print('Error: petOwnerId is empty');
        return null;
      }
      if (adoptionRequest.shelterOwnerId.isEmpty) {
        print('Error: shelterOwnerId is empty');
        return null;
      }
      
      final docRef = await _firestore.collection('adoption_requests').add(adoptionRequest.toFirestore());
      print('Adoption request added successfully with ID: ${docRef.id}');
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding adoption request: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update adoption request
  Future<bool> updateAdoptionRequest(AdoptionRequestModel adoptionRequest) async {
    try {
      print('Updating adoption request: ${adoptionRequest.id}');
      
      final updatedRequest = adoptionRequest.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('adoption_requests')
          .doc(adoptionRequest.id)
          .update(updatedRequest.toFirestore());
      
      print('Adoption request updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating adoption request: $e');
      return false;
    }
  }

  // Delete adoption request (soft delete)
  Future<bool> deleteAdoptionRequest(String requestId) async {
    try {
      print('Soft deleting adoption request: $requestId');
      
      await _firestore.collection('adoption_requests').doc(requestId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Adoption request deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting adoption request: $e');
      return false;
    }
  }

  // Search adoption requests
  Future<List<AdoptionRequestModel>> searchAdoptionRequests({
    required String query,
    String? shelterOwnerId,
    String? petOwnerId,
    AdoptionRequestStatus? status,
  }) async {
    try {
      print('Searching adoption requests with query: $query');
      
      Query baseQuery = _firestore.collection('adoption_requests');
      
      if (shelterOwnerId != null) {
        baseQuery = baseQuery.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      if (petOwnerId != null) {
        baseQuery = baseQuery.where('petOwnerId', isEqualTo: petOwnerId);
      }

      if (status != null) {
        baseQuery = baseQuery.where('status', isEqualTo: status.toString().split('.').last);
      }

      final querySnapshot = await baseQuery
          .where('isActive', isEqualTo: true)
          .get();

      final adoptionRequests = querySnapshot.docs
          .map((doc) {
            try {
              return AdoptionRequestModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing adoption request in search: $e');
              return null;
            }
          })
          .where((request) => request != null)
          .cast<AdoptionRequestModel>()
          .toList();

      // Filter by search query
      final filteredRequests = adoptionRequests.where((request) {
        final searchText = query.toLowerCase();
        return request.petName.toLowerCase().contains(searchText) ||
               request.petOwnerName.toLowerCase().contains(searchText) ||
               request.petType.toLowerCase().contains(searchText) ||
               request.reasonForAdoption.toLowerCase().contains(searchText);
      }).toList();

      print('Found ${filteredRequests.length} adoption requests matching search');
      return filteredRequests;
    } catch (e) {
      print('Error searching adoption requests: $e');
      return [];
    }
  }

  // Get adoption requests by status
  Future<List<AdoptionRequestModel>> getAdoptionRequestsByStatus(AdoptionRequestStatus status, {String? shelterOwnerId}) async {
    try {
      print('Fetching adoption requests by status: $status');
      
      Query query = _firestore
          .collection('adoption_requests')
          .where('status', isEqualTo: status.toString().split('.').last)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final adoptionRequests = querySnapshot.docs
          .map((doc) {
            try {
              return AdoptionRequestModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing adoption request by status: $e');
              return null;
            }
          })
          .where((request) => request != null)
          .cast<AdoptionRequestModel>()
          .toList();

      print('Found ${adoptionRequests.length} adoption requests with status $status');
      return adoptionRequests;
    } catch (e) {
      print('Error getting adoption requests by status: $e');
      return [];
    }
  }

  // Get adoption requests by pet listing ID
  Future<List<AdoptionRequestModel>> getAdoptionRequestsByPetListingId(String petListingId) async {
    try {
      print('Fetching adoption requests for pet listing ID: $petListingId');
      
      final querySnapshot = await _firestore
          .collection('adoption_requests')
          .where('petListingId', isEqualTo: petListingId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} adoption requests for pet listing');

      final adoptionRequests = querySnapshot.docs.map((doc) {
        try {
          print('Processing adoption request document: ${doc.id}');
          return AdoptionRequestModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing adoption request ${doc.id}: $e');
          return null;
        }
      }).where((request) => request != null).cast<AdoptionRequestModel>().toList();

      // Sort manually in code instead of Firestore
      adoptionRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${adoptionRequests.length} adoption requests');
      return adoptionRequests;
    } catch (e) {
      print('Error getting adoption requests by pet listing: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Stream adoption requests by shelter owner ID (real-time updates)
  Stream<List<AdoptionRequestModel>> streamAdoptionRequestsByShelterOwnerId(String shelterOwnerId) {
    print('Setting up stream for adoption requests of shelter owner: $shelterOwnerId');
    
    return _firestore
        .collection('adoption_requests')
        .where('shelterOwnerId', isEqualTo: shelterOwnerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Stream received ${snapshot.docs.length} adoption requests');
          
          return snapshot.docs
              .map((doc) {
                try {
                  return AdoptionRequestModel.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing adoption request in stream: $e');
                  return null;
                }
              })
              .where((request) => request != null)
              .cast<AdoptionRequestModel>()
              .toList();
        });
  }

  // Update adoption request status
  Future<bool> updateAdoptionRequestStatus(String requestId, AdoptionRequestStatus status, {String? response}) async {
    try {
      print('Updating adoption request status: $requestId to $status');
      
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (response != null) {
        updateData['shelterResponse'] = response;
        updateData['responseDate'] = Timestamp.fromDate(DateTime.now());
      }
      
      await _firestore.collection('adoption_requests').doc(requestId).update(updateData);
      
      print('Adoption request status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating adoption request status: $e');
      return false;
    }
  }

  // Check if adoption request exists for pet listing and pet owner
  Future<bool> adoptionRequestExists(String petListingId, String petOwnerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('adoption_requests')
          .where('petListingId', isEqualTo: petListingId)
          .where('petOwnerId', isEqualTo: petOwnerId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking adoption request existence: $e');
      return false;
    }
  }

  // Get adoption request statistics
  Future<Map<String, int>> getAdoptionRequestStatistics(String shelterOwnerId) async {
    try {
      final allRequests = await getAdoptionRequestsByShelterOwnerId(shelterOwnerId);
      
      final stats = <String, int>{
        'total': allRequests.length,
        'pending': allRequests.where((r) => r.status == AdoptionRequestStatus.pending).length,
        'approved': allRequests.where((r) => r.status == AdoptionRequestStatus.approved).length,
        'rejected': allRequests.where((r) => r.status == AdoptionRequestStatus.rejected).length,
        'completed': allRequests.where((r) => r.status == AdoptionRequestStatus.completed).length,
        'cancelled': allRequests.where((r) => r.status == AdoptionRequestStatus.cancelled).length,
      };
      
      return stats;
    } catch (e) {
      print('Error getting adoption request statistics: $e');
      return {};
    }
  }
}
