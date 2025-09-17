import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTestPetImage {
  static Future<void> addTestImageToPet(String petId) async {
    try {
      print('Adding test image to pet: $petId');
      
      // Create a simple base64 image (a colored square)
      final base64Image = _createColoredSquareBase64(200, 200, 0xFF4CAF50); // Green color
      
      // Update the pet document in Firebase
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .update({
        'photoUrls': [base64Image],
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ Successfully added test image to pet: $petId');
    } catch (e) {
      print('❌ Error adding test image to pet $petId: $e');
      rethrow;
    }
  }
  
  static Future<void> addTestImagesToAllPets() async {
    try {
      print('Adding test images to all pets...');
      
      // Get all pets
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .get();
      
      print('Found ${petsSnapshot.docs.length} pets');
      
      for (var doc in petsSnapshot.docs) {
        final data = doc.data();
        final photoUrls = data['photoUrls'] as List<dynamic>? ?? [];
        
        if (photoUrls.isEmpty) {
          await addTestImageToPet(doc.id);
        } else {
          print('Pet ${data['name']} already has ${photoUrls.length} photos');
        }
      }
      
      print('✅ Finished adding test images to all pets');
    } catch (e) {
      print('❌ Error adding test images to all pets: $e');
      rethrow;
    }
  }
  
  static String _createColoredSquareBase64(int width, int height, int color) {
    // Use a simple, known working base64 image
    // This is a 1x1 pixel red PNG that will definitely work
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }
}
