import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/success_story_model.dart';

class SuccessStoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get success stories by shelter owner ID
  Future<List<SuccessStoryModel>> getSuccessStoriesByShelterOwnerId(String shelterOwnerId) async {
    try {
      print('Fetching success stories for shelter owner ID: $shelterOwnerId');
      
      final querySnapshot = await _firestore
          .collection('success_stories')
          .where('shelterOwnerId', isEqualTo: shelterOwnerId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} success stories in Firestore');

      final successStories = querySnapshot.docs.map((doc) {
        try {
          print('Processing success story document: ${doc.id}');
          return SuccessStoryModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing success story ${doc.id}: $e');
          return null;
        }
      }).where((story) => story != null).cast<SuccessStoryModel>().toList();

      // Sort manually in code instead of Firestore
      successStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${successStories.length} success stories');
      return successStories;
    } catch (e) {
      print('Error getting success stories: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get all public success stories (for display to pet owners)
  Future<List<SuccessStoryModel>> getAllPublicSuccessStories() async {
    try {
      print('Fetching all public success stories');
      
      final querySnapshot = await _firestore
          .collection('success_stories')
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} public success stories in Firestore');

      final successStories = querySnapshot.docs.map((doc) {
        try {
          print('Processing success story document: ${doc.id}');
          return SuccessStoryModel.fromFirestore(doc);
        } catch (e) {
          print('Error processing success story ${doc.id}: $e');
          return null;
        }
      }).where((story) => story != null).cast<SuccessStoryModel>().toList();

      // Sort manually in code instead of Firestore
      successStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully parsed ${successStories.length} public success stories');
      return successStories;
    } catch (e) {
      print('Error getting public success stories: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get success story by ID
  Future<SuccessStoryModel?> getSuccessStoryById(String storyId) async {
    try {
      print('Fetching success story with ID: $storyId');
      final doc = await _firestore.collection('success_stories').doc(storyId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Success story found: ${doc.data()}');
        return SuccessStoryModel.fromFirestore(doc);
      } else {
        print('Success story not found or has no data');
      }
    } catch (e) {
      print('Error getting success story: $e');
    }
    return null;
  }

  // Add new success story
  Future<String?> addSuccessStory(SuccessStoryModel successStory) async {
    try {
      print('Adding new success story: ${successStory.storyTitle}');
      print('Success story data to save: ${successStory.toFirestore()}');
      
      final docRef = await _firestore.collection('success_stories').add(successStory.toFirestore());
      print('Success story added successfully with ID: ${docRef.id}');
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding success story: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update success story
  Future<bool> updateSuccessStory(SuccessStoryModel successStory) async {
    try {
      print('Updating success story: ${successStory.id} - ${successStory.storyTitle}');
      
      final updatedStory = successStory.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('success_stories')
          .doc(successStory.id)
          .update(updatedStory.toFirestore());
      
      print('Success story updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating success story: $e');
      return false;
    }
  }

  // Delete success story (soft delete)
  Future<bool> deleteSuccessStory(String storyId) async {
    try {
      print('Soft deleting success story: $storyId');
      
      await _firestore.collection('success_stories').doc(storyId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Success story deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting success story: $e');
      return false;
    }
  }

  // Upload success story photo
  Future<String?> uploadSuccessStoryPhoto(File imageFile, String storyId) async {
    try {
      print('Uploading photo for success story: $storyId');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('success_story_photos/$storyId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // Add photo URL to success story
  Future<bool> addPhotoToSuccessStory(String storyId, String photoUrl) async {
    try {
      print('Adding photo URL to success story: $storyId');
      
      final storyDoc = await _firestore.collection('success_stories').doc(storyId).get();
      if (!storyDoc.exists) {
        print('Success story not found');
        return false;
      }
      
      final story = SuccessStoryModel.fromFirestore(storyDoc);
      final updatedPhotoUrls = List<String>.from(story.photoUrls)..add(photoUrl);
      
      await _firestore.collection('success_stories').doc(storyId).update({
        'photoUrls': updatedPhotoUrls,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Photo URL added successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding photo URL to success story: $e');
      return false;
    }
  }

  // Search success stories
  Future<List<SuccessStoryModel>> searchSuccessStories({
    required String query,
    String? shelterOwnerId,
  }) async {
    try {
      print('Searching success stories with query: $query');
      
      Query baseQuery = _firestore.collection('success_stories');
      
      if (shelterOwnerId != null) {
        baseQuery = baseQuery.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await baseQuery
          .where('isActive', isEqualTo: true)
          .get();

      final successStories = querySnapshot.docs
          .map((doc) {
            try {
              return SuccessStoryModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing success story in search: $e');
              return null;
            }
          })
          .where((story) => story != null)
          .cast<SuccessStoryModel>()
          .toList();

      // Filter by search query
      final filteredStories = successStories.where((story) {
        final searchText = query.toLowerCase();
        return story.storyTitle.toLowerCase().contains(searchText) ||
               story.storyDescription.toLowerCase().contains(searchText) ||
               story.petName.toLowerCase().contains(searchText) ||
               story.adopterName.toLowerCase().contains(searchText) ||
               story.petType.toLowerCase().contains(searchText);
      }).toList();

      print('Found ${filteredStories.length} success stories matching search');
      return filteredStories;
    } catch (e) {
      print('Error searching success stories: $e');
      return [];
    }
  }

  // Get featured success stories
  Future<List<SuccessStoryModel>> getFeaturedSuccessStories({String? shelterOwnerId}) async {
    try {
      print('Fetching featured success stories');
      
      Query query = _firestore
          .collection('success_stories')
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true);
      
      if (shelterOwnerId != null) {
        query = query.where('shelterOwnerId', isEqualTo: shelterOwnerId);
      }

      final querySnapshot = await query.get();

      final successStories = querySnapshot.docs
          .map((doc) {
            try {
              return SuccessStoryModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing featured success story: $e');
              return null;
            }
          })
          .where((story) => story != null)
          .cast<SuccessStoryModel>()
          .toList();

      print('Found ${successStories.length} featured success stories');
      return successStories;
    } catch (e) {
      print('Error getting featured success stories: $e');
      return [];
    }
  }

  // Stream success stories by shelter owner ID (real-time updates)
  Stream<List<SuccessStoryModel>> streamSuccessStoriesByShelterOwnerId(String shelterOwnerId) {
    print('Setting up stream for success stories of shelter owner: $shelterOwnerId');
    
    return _firestore
        .collection('success_stories')
        .where('shelterOwnerId', isEqualTo: shelterOwnerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Stream received ${snapshot.docs.length} success stories');
          
          return snapshot.docs
              .map((doc) {
                try {
                  return SuccessStoryModel.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing success story in stream: $e');
                  return null;
                }
              })
              .where((story) => story != null)
              .cast<SuccessStoryModel>()
              .toList();
        });
  }

  // Update success story featured status
  Future<bool> updateSuccessStoryFeaturedStatus(String storyId, bool isFeatured) async {
    try {
      print('Updating success story featured status: $storyId to $isFeatured');
      
      await _firestore.collection('success_stories').doc(storyId).update({
        'isFeatured': isFeatured,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Success story featured status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating success story featured status: $e');
      return false;
    }
  }

  // Get success story statistics
  Future<Map<String, int>> getSuccessStoryStatistics(String shelterOwnerId) async {
    try {
      final allStories = await getSuccessStoriesByShelterOwnerId(shelterOwnerId);
      
      final stats = <String, int>{
        'total': allStories.length,
        'featured': allStories.where((s) => s.isFeatured).length,
        'thisMonth': allStories.where((s) => 
          s.createdAt.month == DateTime.now().month && 
          s.createdAt.year == DateTime.now().year
        ).length,
        'thisYear': allStories.where((s) => s.createdAt.year == DateTime.now().year).length,
      };
      
      return stats;
    } catch (e) {
      print('Error getting success story statistics: $e');
      return {};
    }
  }
  
  // Generate sample success stories for testing
  Future<void> generateSampleSuccessStories() async {
    try {
      print('Generating sample success stories...');
      
      // Check if sample stories already exist
      final existingStories = await _firestore
          .collection('success_stories')
          .limit(1)
          .get();
      
      if (existingStories.docs.isNotEmpty) {
        print('Sample success stories already exist, skipping generation');
        return;
      }
      
      // Sample success stories with placeholder images
      final sampleStories = [
        {
          'shelterOwnerId': 'sample_shelter_1',
          'petName': 'Milo',
          'petType': 'Cat',
          'adopterName': 'Mom',
          'adopterEmail': 'adopter1@example.com',
          'storyTitle': 'A lost kitty',
          'storyDescription': 'We found a kitten lost in heavy rain near Karachi. After nursing it back to health, we found the perfect loving home. Milo now enjoys playing with children and has become a beloved family member.',
          'photoUrls': [
            'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          ],
          'adoptionDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
          'isFeatured': true,
        },
        {
          'shelterOwnerId': 'sample_shelter_2',
          'petName': 'Buddy',
          'petType': 'Dog',
          'adopterName': 'Johnson Family',
          'adopterEmail': 'johnsons@example.com',
          'storyTitle': 'From Streets to Hearts',
          'storyDescription': 'Buddy was found wandering the streets, scared and malnourished. With love, care, and patience, he transformed into a happy, healthy dog who now brings joy to his new family every day.',
          'photoUrls': [
            'https://images.unsplash.com/photo-1552053831-71594a27632d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          ],
          'adoptionDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
          'isFeatured': true,
        },
        {
          'shelterOwnerId': 'sample_shelter_1',
          'petName': 'Luna',
          'petType': 'Cat',
          'adopterName': 'Sarah Miller',
          'adopterEmail': 'sarah.miller@example.com',
          'storyTitle': 'Second Chance at Love',
          'storyDescription': 'Luna was a senior cat who had lost hope until she found her forever home. Now she spends her days lounging in sunny spots and purring contentedly in her new mother\'s lap.',
          'photoUrls': [
            'https://images.unsplash.com/photo-1573865526739-10659fec78a5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          ],
          'adoptionDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
          'isFeatured': true,
        },
        {
          'shelterOwnerId': 'sample_shelter_2',
          'petName': 'Rocky',
          'petType': 'Dog',
          'adopterName': 'Martinez Family',
          'adopterEmail': 'martinez@example.com',
          'storyTitle': 'Adventure Awaits',
          'storyDescription': 'Rocky was an energetic young dog who needed an active family. He found the perfect match with the Martinez family who love hiking and outdoor adventures. Now Rocky explores trails every weekend!',
          'photoUrls': [
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          ],
          'adoptionDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
          'isFeatured': true,
        },
        {
          'shelterOwnerId': 'sample_shelter_3',
          'petName': 'Whiskers',
          'petType': 'Cat',
          'adopterName': 'Emma Thompson',
          'adopterEmail': 'emma.t@example.com',
          'storyTitle': 'Shy to Confident',
          'storyDescription': 'Whiskers was extremely shy and would hide from everyone. With patience and gentle care, Emma helped Whiskers come out of her shell. Now she greets visitors at the door!',
          'photoUrls': [
            'https://images.unsplash.com/photo-1606214174585-fe31582dc6ee?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          ],
          'adoptionDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
          'isFeatured': true,
        },
      ];
      
      // Add each sample story to Firestore
      for (final story in sampleStories) {
        await _firestore.collection('success_stories').add(story);
      }
      
      print('Sample success stories created successfully!');
      notifyListeners();
    } catch (e) {
      print('Error generating sample success stories: $e');
    }
  }
}
