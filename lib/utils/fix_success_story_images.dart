import 'package:cloud_firestore/cloud_firestore.dart';

class FixSuccessStoryImages {
  static Future<void> addImageToSpecificStory() async {
    try {
      // The story ID from your Firebase data
      const storyId = 'on8zaf7xQJlpo4HliKsc';
      
      // Create a simple base64 image
      final base64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
      
      // Add the image to the success story
      final docRef = FirebaseFirestore.instance.collection('success_stories').doc(storyId);
      await docRef.update({
        'photoUrls': FieldValue.arrayUnion([base64Image]),
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ Successfully added base64 image to success story: $storyId');
    } catch (e) {
      print('❌ Error adding image to success story: $e');
    }
  }
  
  static Future<void> addImagesToAllStories() async {
    try {
      // Get all success stories
      final querySnapshot = await FirebaseFirestore.instance
          .collection('success_stories')
          .where('isActive', isEqualTo: true)
          .get();
      
      print('Found ${querySnapshot.docs.length} success stories');
      
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final storyId = doc.id;
        
        // Create a simple base64 image
        final base64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        
        // Add the image to the success story
        await doc.reference.update({
          'photoUrls': FieldValue.arrayUnion([base64Image]),
          'updatedAt': Timestamp.now(),
        });
        
        print('✅ Added image to story ${i + 1}: $storyId');
      }
      
      print('✅ Successfully added images to all success stories');
    } catch (e) {
      print('❌ Error adding images to all stories: $e');
    }
  }
}
