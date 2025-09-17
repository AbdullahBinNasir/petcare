import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_utils.dart';

class BlogImageHelper {
  /// Add base64 image to a specific blog post by ID
  static Future<void> addBase64ImageToBlogPost(String postId, String base64Image) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('blog_posts').doc(postId);
      await docRef.update({
        'featuredImageUrl': base64Image,
        'updatedAt': Timestamp.now(),
      });
      print('Successfully added base64 image to blog post $postId');
    } catch (e) {
      print('Error adding base64 image to blog post $postId: $e');
    }
  }

  /// Add base64 images to all blog posts
  static Future<void> addImagesToAllBlogPosts() async {
    try {
      print('🔄 Adding images to all blog posts...');
      
      // Get all blog posts
      final querySnapshot = await FirebaseFirestore.instance
          .collection('blog_posts')
          .get();
      
      final sampleImages = ImageUtils.getSampleBase64Images();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final category = data['category'] ?? 'general';
        
        // Choose appropriate image based on category
        String base64Image;
        switch (category.toString().toLowerCase()) {
          case 'training':
            base64Image = sampleImages['dog_food'] ?? _createSimpleBase64Image();
            break;
          case 'nutrition':
            base64Image = sampleImages['cat_toy'] ?? _createSimpleBase64Image();
            break;
          case 'health':
            base64Image = sampleImages['grooming_kit'] ?? _createSimpleBase64Image();
            break;
          case 'grooming':
            base64Image = sampleImages['kong_toy'] ?? _createSimpleBase64Image();
            break;
          case 'behavior':
            base64Image = sampleImages['dog_food'] ?? _createSimpleBase64Image();
            break;
          default:
            base64Image = sampleImages['grooming_kit'] ?? _createSimpleBase64Image();
        }
        
        // Update the blog post
        await doc.reference.update({
          'featuredImageUrl': base64Image,
          'updatedAt': Timestamp.now(),
        });
        
        print('✅ Added image to blog post: $title');
      }
      
      print('🎉 Successfully added images to ${querySnapshot.docs.length} blog posts!');
    } catch (e) {
      print('❌ Error adding images to blog posts: $e');
    }
  }

  static String _createSimpleBase64Image() {
    // Simple 1x1 pixel PNG
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  }
}
