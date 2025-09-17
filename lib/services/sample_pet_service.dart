import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_pet_data.dart';
import '../models/pet_model.dart';

class SamplePetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate database with sample pets
  static Future<void> populatePetsWithSampleData() async {
    try {
      print('🔄 Starting to populate pets with sample data...');
      
      final samplePets = SamplePetData.getSamplePets();
      
      for (final pet in samplePets) {
        // Check if pet already exists
        final docRef = _firestore.collection('pets').doc(pet.id);
        final doc = await docRef.get();
        
        if (!doc.exists) {
          await docRef.set(pet.toFirestore());
          print('✅ Added sample pet: ${pet.name}');
        } else {
          print('⏭️ Pet already exists: ${pet.name}');
        }
      }
      
      print('🎉 Successfully populated pets with ${samplePets.length} sample pets!');
    } catch (e) {
      print('❌ Error populating pets with sample data: $e');
      rethrow;
    }
  }

  /// Add a single sample pet with base64 image
  static Future<void> addSamplePetWithBase64Image() async {
    try {
      final pet = SamplePetData.getSamplePetWithBase64Image();
      await _firestore.collection('pets').doc(pet.id).set(pet.toFirestore());
      print('✅ Added sample pet with base64 image: ${pet.name}');
    } catch (e) {
      print('❌ Error adding sample pet with base64 image: $e');
      rethrow;
    }
  }

  /// Update existing pet with base64 image
  static Future<void> updatePetWithBase64Image(String petId) async {
    try {
      final base64Image = SamplePetData.getSimpleBase64Image();
      
      await _firestore.collection('pets').doc(petId).update({
        'photoUrls': [base64Image],
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('✅ Updated pet $petId with base64 image');
    } catch (e) {
      print('❌ Error updating pet with base64 image: $e');
      rethrow;
    }
  }

  /// Get sample pets by owner ID
  static List<PetModel> getSamplePetsByOwnerId(String ownerId) {
    return SamplePetData.getSamplePets()
        .where((pet) => pet.ownerId == ownerId)
        .toList();
  }

  /// Get all sample pets
  static List<PetModel> getAllSamplePets() {
    return SamplePetData.getSamplePets();
  }

  /// Check if pets have sample data
  static Future<bool> hasSamplePetData() async {
    try {
      final samplePets = SamplePetData.getSamplePets();
      if (samplePets.isEmpty) return false;
      
      final doc = await _firestore.collection('pets').doc(samplePets.first.id).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking for sample pet data: $e');
      return false;
    }
  }

  /// Get sample pet data statistics
  static Future<Map<String, int>> getSamplePetDataStats() async {
    try {
      final samplePets = SamplePetData.getSamplePets();
      int existingCount = 0;
      
      for (final pet in samplePets) {
        final doc = await _firestore.collection('pets').doc(pet.id).get();
        if (doc.exists) existingCount++;
      }
      
      return {
        'total': samplePets.length,
        'existing': existingCount,
        'missing': samplePets.length - existingCount,
      };
    } catch (e) {
      print('❌ Error getting sample pet data stats: $e');
      return {'total': 0, 'existing': 0, 'missing': 0};
    }
  }
}
