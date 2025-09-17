import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessStoryImageHelper {
  static Future<void> addBase64ImageToSuccessStory(String storyId, String base64Image) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('success_stories').doc(storyId);
      await docRef.update({
        'photoUrls': FieldValue.arrayUnion([base64Image]),
        'updatedAt': Timestamp.now(),
      });
      print('Successfully added base64 image to success story $storyId');
    } catch (e) {
      print('Error adding base64 image to success story $storyId: $e');
    }
  }

  static String createColoredBase64Image(String colorName) {
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
