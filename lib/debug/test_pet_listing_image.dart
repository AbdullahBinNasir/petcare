import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/fix_pet_listing_images.dart';

class TestPetListingImage {
  /// Test adding image to a specific pet listing
  static Future<void> testAddImageToAngela() async {
    try {
      print('🔄 Testing image addition to Angela pet listing...');
      
      // First, let's find the pet listing with name "Angela"
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pet_listings')
          .where('name', isEqualTo: 'Angela')
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final listingId = doc.id;
        print('Found Angela pet listing with ID: $listingId');
        
        // Add image to this specific listing
        await FixPetListingImages.addImageToSpecificPetListing(listingId);
        
        // Verify the image was added
        final updatedDoc = await FirebaseFirestore.instance
            .collection('pet_listings')
            .doc(listingId)
            .get();
        
        final data = updatedDoc.data();
        final photoUrls = data?['photoUrls'] as List<dynamic>? ?? [];
        print('Photo URLs after update: $photoUrls');
        print('Number of images: ${photoUrls.length}');
        
      } else {
        print('❌ No pet listing found with name "Angela"');
      }
    } catch (e) {
      print('❌ Error testing image addition: $e');
    }
  }
  
  /// Test adding images to all pet listings
  static Future<void> testAddImagesToAll() async {
    try {
      print('🔄 Testing image addition to all pet listings...');
      await FixPetListingImages.addImagesToAllPetListings();
    } catch (e) {
      print('❌ Error testing image addition to all: $e');
    }
  }
}
