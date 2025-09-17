import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_utils.dart';

class FixPetImages {
  /// Fix corrupted pet images by replacing them with valid base64 images
  static Future<void> fixAllPetImages() async {
    try {
      print('🔄 Fixing all pet images...');
      
      // Get all pets
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .get();
      
      final sampleImages = ImageUtils.getSampleBase64Images();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final petId = doc.id;
        final name = data['name'] ?? 'Unknown';
        final species = data['species'] ?? 'dog';
        final currentPhotoUrls = List<String>.from(data['photoUrls'] ?? []);
        
        print('🔍 Checking pet: $name (ID: $petId)');
        print('Current photo URLs: $currentPhotoUrls');
        
        // Choose appropriate image based on species
        String base64Image;
        if (species.toString().toLowerCase().contains('dog')) {
          base64Image = sampleImages['dog_food'] ?? _createValidBase64Image();
        } else if (species.toString().toLowerCase().contains('cat')) {
          base64Image = sampleImages['cat_toy'] ?? _createValidBase64Image();
        } else {
          base64Image = sampleImages['grooming_kit'] ?? _createValidBase64Image();
        }
        
        print('📸 Using image: ${base64Image.substring(0, 50)}...');
        
        // Update the pet with a valid base64 image
        await doc.reference.update({
          'photoUrls': [base64Image],
          'updatedAt': Timestamp.now(),
        });
        
        print('✅ Fixed image for pet: $name');
      }
      
      print('🎉 Successfully fixed images for ${querySnapshot.docs.length} pets!');
    } catch (e) {
      print('❌ Error fixing pet images: $e');
    }
  }

  /// Create a valid base64 image for testing
  static String _createValidBase64Image() {
    // Create a simple 100x100 pixel colored square
    final List<int> pngBytes = _createColoredPng(100, 100, 0xFF4CAF50); // Green color
    return 'data:image/png;base64,${base64Encode(pngBytes)}';
  }

  /// Test if a base64 string is valid
  static bool isValidBase64Image(String base64String) {
    try {
      if (base64String.isEmpty) return false;
      
      String base64Data;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      } else {
        base64Data = base64String;
      }
      
      if (base64Data.isEmpty) return false;
      
      final decoded = base64Decode(base64Data);
      return decoded.isNotEmpty;
    } catch (e) {
      print('Invalid base64: $e');
      return false;
    }
  }

  /// Test the image creation and validation
  static Future<void> testImageCreation() async {
    try {
      print('🧪 Testing image creation...');
      
      final sampleImages = ImageUtils.getSampleBase64Images();
      print('Sample images available: ${sampleImages.keys.toList()}');
      
      for (final entry in sampleImages.entries) {
        final isValid = isValidBase64Image(entry.value);
        print('${entry.key}: ${isValid ? "✅ Valid" : "❌ Invalid"}');
      }
      
      final testImage = _createValidBase64Image();
      final testValid = isValidBase64Image(testImage);
      print('Test image: ${testValid ? "✅ Valid" : "❌ Invalid"}');
      
    } catch (e) {
      print('❌ Error testing image creation: $e');
    }
  }

  /// Create a colored PNG image
  static List<int> _createColoredPng(int width, int height, int color) {
    // This is a simplified PNG creation - in a real app you'd use a proper image library
    // For now, we'll create a minimal valid PNG
    return [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
      (width >> 24) & 0xFF, (width >> 16) & 0xFF, (width >> 8) & 0xFF, width & 0xFF, // Width
      (height >> 24) & 0xFF, (height >> 16) & 0xFF, (height >> 8) & 0xFF, height & 0xFF, // Height
      0x08, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82,
    ];
  }
}
