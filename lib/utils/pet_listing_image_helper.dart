import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_utils.dart';

class PetListingImageHelper {
  static Future<void> addBase64ImageToPetListing(String listingId, String base64Image) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('pet_listings').doc(listingId);
      await docRef.update({
        'photoUrls': FieldValue.arrayUnion([base64Image]),
        'updatedAt': Timestamp.now(),
      });
      print('Successfully added base64 image to pet listing $listingId');
    } catch (e) {
      print('Error adding base64 image to pet listing $listingId: $e');
    }
  }

  static String createColoredBase64Image(String colorName) {
    // Use the existing image utils to get a proper sample image
    final sampleImages = ImageUtils.getSampleBase64Images();
    
    // Return different images based on the color name
    if (colorName.toLowerCase().contains('dog')) {
      return sampleImages['dog_food'] ?? _createSimpleBase64Image();
    } else if (colorName.toLowerCase().contains('cat')) {
      return sampleImages['cat_toy'] ?? _createSimpleBase64Image();
    } else {
      return sampleImages['grooming_kit'] ?? _createSimpleBase64Image();
    }
  }

  static String _createSimpleBase64Image() {
    // Create a simple colored square image
    final List<int> pixel = [255, 255, 255, 255]; // White pixel
    final List<int> pngBytes = _createPngBytes(1, 1, pixel);
    return 'data:image/png;base64,${base64Encode(pngBytes)}';
  }

  static List<int> _createPngBytes(int width, int height, List<int> pixel) {
    // Simple PNG for testing
    return [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, width, 0x00, 0x00, 0x00, height,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82,
    ];
  }
}
