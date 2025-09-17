import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetImageHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add base64 image to an existing pet
  static Future<void> addBase64ImageToPet(String petId, String base64ImageData) async {
    try {
      await _firestore.collection('pets').doc(petId).update({
        'photoUrls': [base64ImageData],
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Added base64 image to pet: $petId');
    } catch (e) {
      print('❌ Error adding base64 image to pet: $e');
      rethrow;
    }
  }

  /// Create a simple colored base64 image
  static String createColoredBase64Image(String color) {
    // This is a very simple 1x1 pixel PNG with a specific color
    // In a real app, you'd want to create proper images
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }

  /// Create a base64 image from bytes
  static String createBase64ImageFromBytes(Uint8List bytes, String mimeType) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  /// Validate base64 image data
  static bool isValidBase64Image(String imageData) {
    try {
      if (!imageData.startsWith('data:image/')) return false;
      final base64Part = imageData.split(',')[1];
      base64Decode(base64Part);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get image MIME type from base64 data URL
  static String getImageMimeType(String base64DataUrl) {
    if (base64DataUrl.startsWith('data:image/')) {
      return base64DataUrl.split(';')[0].split(':')[1];
    }
    return 'image/png';
  }

  /// Extract base64 string from data URL
  static String extractBase64String(String base64DataUrl) {
    if (base64DataUrl.contains(',')) {
      return base64DataUrl.split(',')[1];
    }
    return base64DataUrl;
  }

  /// Convert base64 string to bytes
  static Uint8List base64StringToBytes(String base64String) {
    return base64Decode(base64String);
  }
}
