import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_store_items.dart';
import '../models/store_item_model.dart';

class SampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate store with sample items
  static Future<void> populateStoreWithSampleData() async {
    try {
      print('🔄 Starting to populate store with sample data...');
      
      final sampleItems = SampleStoreItems.getSampleItems();
      
      for (final item in sampleItems) {
        // Check if item already exists
        final docRef = _firestore.collection('store_items').doc(item.id);
        final doc = await docRef.get();
        
        if (!doc.exists) {
          await docRef.set(item.toFirestore());
          print('✅ Added sample item: ${item.name}');
        } else {
          print('⏭️ Item already exists: ${item.name}');
        }
      }
      
      print('🎉 Successfully populated store with ${sampleItems.length} sample items!');
    } catch (e) {
      print('❌ Error populating store with sample data: $e');
      rethrow;
    }
  }

  /// Clear all sample data from store
  static Future<void> clearSampleData() async {
    try {
      print('🔄 Clearing sample data from store...');
      
      final sampleItems = SampleStoreItems.getSampleItems();
      final batch = _firestore.batch();
      
      for (final item in sampleItems) {
        final docRef = _firestore.collection('store_items').doc(item.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      print('✅ Cleared ${sampleItems.length} sample items from store');
    } catch (e) {
      print('❌ Error clearing sample data: $e');
      rethrow;
    }
  }

  /// Add a single sample item
  static Future<void> addSampleItem(StoreItemModel item) async {
    try {
      await _firestore.collection('store_items').doc(item.id).set(item.toFirestore());
      print('✅ Added sample item: ${item.name}');
    } catch (e) {
      print('❌ Error adding sample item: $e');
      rethrow;
    }
  }

  /// Get sample items by category
  static List<StoreItemModel> getSampleItemsByCategory(StoreCategory category) {
    return SampleStoreItems.getItemsByCategory(category);
  }

  /// Get all sample items
  static List<StoreItemModel> getAllSampleItems() {
    return SampleStoreItems.getSampleItems();
  }

  /// Check if store has sample data
  static Future<bool> hasSampleData() async {
    try {
      final sampleItems = SampleStoreItems.getSampleItems();
      if (sampleItems.isEmpty) return false;
      
      final doc = await _firestore.collection('store_items').doc(sampleItems.first.id).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking for sample data: $e');
      return false;
    }
  }

  /// Get sample data statistics
  static Future<Map<String, int>> getSampleDataStats() async {
    try {
      final sampleItems = SampleStoreItems.getSampleItems();
      int existingCount = 0;
      
      for (final item in sampleItems) {
        final doc = await _firestore.collection('store_items').doc(item.id).get();
        if (doc.exists) existingCount++;
      }
      
      return {
        'total': sampleItems.length,
        'existing': existingCount,
        'missing': sampleItems.length - existingCount,
      };
    } catch (e) {
      print('❌ Error getting sample data stats: $e');
      return {'total': 0, 'existing': 0, 'missing': 0};
    }
  }
}
