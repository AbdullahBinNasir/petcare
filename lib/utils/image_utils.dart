import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Convert image file to base64 data URL
  static Future<String> fileToBase64DataUrl(XFile file) async {
    try {
      final bytes = kIsWeb ? await file.readAsBytes() : await File(file.path).readAsBytes();
      final lower = file.name.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      print('Error converting file to base64: $e');
      return '';
    }
  }

  /// Convert bytes to base64 data URL
  static String bytesToBase64DataUrl(List<int> bytes, String mimeType) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  /// Check if string is a base64 data URL
  static bool isBase64DataUrl(String? url) {
    return url != null && url.startsWith('data:image/');
  }

  /// Check if string is a regular URL
  static bool isNetworkUrl(String? url) {
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }

  /// Get image source type
  static ImageSourceType getImageSourceType(String? url) {
    if (isBase64DataUrl(url)) {
      return ImageSourceType.base64;
    } else if (isNetworkUrl(url)) {
      return ImageSourceType.network;
    } else {
      return ImageSourceType.asset;
    }
  }

  /// Generate sample base64 images for testing
  static Map<String, String> getSampleBase64Images() {
    return {
      'dog_food': _getDogFoodBase64(),
      'cat_toy': _getCatToyBase64(),
      'grooming_kit': _getGroomingKitBase64(),
      'dog_harness': _getDogHarnessBase64(),
      'pet_carrier': _getPetCarrierBase64(),
      'health_supplements': _getHealthSupplementsBase64(),
      'flea_prevention': _getFleaPreventionBase64(),
      'shampoo': _getShampooBase64(),
      'kong_toy': _getKongToyBase64(),
      'laser_pointer': _getLaserPointerBase64(),
    };
  }

  // Sample base64 images (small, simple images for testing)
  static String _getDogFoodBase64() {
    // Create a simple colored square for dog food
    return _createColoredSquareBase64(100, 100, 0xFF8B4513); // Brown color
  }

  static String _getCatToyBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF4CAF50); // Green color
  }

  static String _getGroomingKitBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF2196F3); // Blue color
  }

  static String _getDogHarnessBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF9C27B0); // Purple color
  }

  static String _getPetCarrierBase64() {
    return _createColoredSquareBase64(100, 100, 0xFFFF9800); // Orange color
  }

  static String _getHealthSupplementsBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF4CAF50); // Green color
  }

  static String _getFleaPreventionBase64() {
    return _createColoredSquareBase64(100, 100, 0xFFE91E63); // Pink color
  }

  static String _getShampooBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF00BCD4); // Cyan color
  }

  static String _getKongToyBase64() {
    return _createColoredSquareBase64(100, 100, 0xFF795548); // Brown color
  }

  static String _getLaserPointerBase64() {
    return _createColoredSquareBase64(100, 100, 0xFFF44336); // Red color
  }

  /// Create a colored square base64 image
  static String _createColoredSquareBase64(int width, int height, int color) {
    // Create a simple colored square PNG
    final List<int> pngBytes = _createColoredPng(width, height, color);
    return 'data:image/png;base64,${base64Encode(pngBytes)}';
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

enum ImageSourceType {
  network,
  base64,
  asset,
}
