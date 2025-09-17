import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_utils.dart';

class FixPetListingImages {
  /// Add base64 image to a specific pet listing by ID
  static Future<void> addImageToSpecificPetListing(String listingId) async {
    try {
      print('🔄 Adding image to pet listing: $listingId');
      
      // Get sample images
      final sampleImages = ImageUtils.getSampleBase64Images();
      final base64Image = sampleImages['cat_toy'] ?? _createSimpleBase64Image();
      
      // Update the pet listing with the image
      final docRef = FirebaseFirestore.instance.collection('pet_listings').doc(listingId);
      await docRef.update({
        'photoUrls': FieldValue.arrayUnion([base64Image]),
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ Successfully added image to pet listing: $listingId');
    } catch (e) {
      print('❌ Error adding image to pet listing $listingId: $e');
    }
  }

  /// Add images to all pet listings
  static Future<void> addImagesToAllPetListings() async {
    try {
      print('🔄 Adding images to all pet listings...');
      
      // Get all pet listings
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pet_listings')
          .get();
      
      final sampleImages = ImageUtils.getSampleBase64Images();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final type = data['type'] ?? 'cat';
        
        // Choose appropriate image based on type
        String base64Image;
        if (type.toString().toLowerCase().contains('dog')) {
          base64Image = sampleImages['dog_food'] ?? _createSimpleBase64Image();
        } else if (type.toString().toLowerCase().contains('cat')) {
          base64Image = sampleImages['cat_toy'] ?? _createSimpleBase64Image();
        } else {
          base64Image = sampleImages['grooming_kit'] ?? _createSimpleBase64Image();
        }
        
        // Update the pet listing
        await doc.reference.update({
          'photoUrls': FieldValue.arrayUnion([base64Image]),
          'updatedAt': Timestamp.now(),
        });
        
        print('✅ Added image to pet listing: $name');
      }
      
      print('🎉 Successfully added images to ${querySnapshot.docs.length} pet listings!');
    } catch (e) {
      print('❌ Error adding images to pet listings: $e');
    }
  }

  static String _createSimpleBase64Image() {
    // Simple 1x1 pixel PNG
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }
}
