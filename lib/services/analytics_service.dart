import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item_model.dart';

class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Analytics data
  Map<String, int> _itemClickCounts = {};
  Map<String, int> _itemViewCounts = {};
  Map<String, List<String>> _userInterests = {};
  Map<String, double> _categoryPopularity = {};
  
  // Getters
  Map<String, int> get itemClickCounts => _itemClickCounts;
  Map<String, int> get itemViewCounts => _itemViewCounts;
  Map<String, List<String>> get userInterests => _userInterests;
  Map<String, double> get categoryPopularity => _categoryPopularity;

  /// Track when a user views a store item
  Future<void> trackItemView(String itemId, String userId, StoreCategory category) async {
    try {
      debugPrint('Analytics: Tracking item view - itemId: $itemId, userId: $userId, category: $category');
      
      // Update local tracking
      _itemViewCounts[itemId] = (_itemViewCounts[itemId] ?? 0) + 1;
      
      // Update user interests
      if (!_userInterests.containsKey(userId)) {
        _userInterests[userId] = [];
      }
      final categoryName = _getCategoryName(category);
      if (!_userInterests[userId]!.contains(categoryName)) {
        _userInterests[userId]!.add(categoryName);
      }
      
      // Update category popularity
      _categoryPopularity[categoryName] = (_categoryPopularity[categoryName] ?? 0) + 1;

      // Update in Firestore
      await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .doc(itemId)
          .set({
        'viewCount': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
        'category': category.toString().split('.').last,
      }, SetOptions(merge: true));

      // Track user interest
      await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc(userId)
          .set({
        'interests': FieldValue.arrayUnion([categoryName]),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update category analytics
      await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .doc(categoryName)
          .set({
        'viewCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking item view: $e');
    }
  }

  /// Track when a user clicks on a store item (for purchase)
  Future<void> trackItemClick(String itemId, String userId, StoreCategory category) async {
    try {
      debugPrint('Analytics: Tracking item click - itemId: $itemId, userId: $userId, category: $category');
      
      // Update local tracking
      _itemClickCounts[itemId] = (_itemClickCounts[itemId] ?? 0) + 1;
      
      // Update in Firestore
      await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .doc(itemId)
          .set({
        'clickCount': FieldValue.increment(1),
        'lastClicked': FieldValue.serverTimestamp(),
        'category': category.toString().split('.').last,
      }, SetOptions(merge: true));

      // Track user purchase interest
      await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc(userId)
          .set({
        'purchaseInterests': FieldValue.arrayUnion([itemId]),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking item click: $e');
    }
  }

  /// Track when a user adds/removes an item from favorites
  Future<void> trackFavoriteAction(String itemId, String userId, bool isFavorite, StoreCategory category) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('favorite_actions')
          .collection('items')
          .doc(itemId)
          .set({
        'favoriteCount': isFavorite ? FieldValue.increment(1) : FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
        'category': category.toString().split('.').last,
      }, SetOptions(merge: true));

      // Track user preference
      await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc(userId)
          .set({
        'favoriteCategories': isFavorite 
            ? FieldValue.arrayUnion([_getCategoryName(category)])
            : FieldValue.arrayRemove([_getCategoryName(category)]),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking favorite action: $e');
    }
  }

  /// Track search queries
  Future<void> trackSearchQuery(String query, String userId, List<String> results) async {
    try {
      await _firestore
          .collection('analytics')
          .doc('search_queries')
          .collection('queries')
          .add({
        'query': query,
        'userId': userId,
        'resultCount': results.length,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking search query: $e');
    }
  }

  /// Get analytics data for admin dashboard
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      debugPrint('Analytics: Getting analytics data from Firebase...');
      final analytics = <String, dynamic>{};
      
      // Get most viewed items
      final mostViewed = await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .orderBy('viewCount', descending: true)
          .limit(10)
          .get();
      
      // Fetch item names for most viewed items
      final mostViewedWithNames = <Map<String, dynamic>>[];
      for (final doc in mostViewed.docs) {
        final data = doc.data();
        final itemId = doc.id;
        
        // Get item name from store items collection
        String itemName = 'Unknown Item';
        try {
          final itemDoc = await _firestore.collection('store_items').doc(itemId).get();
          if (itemDoc.exists) {
            final itemData = itemDoc.data() as Map<String, dynamic>;
            itemName = itemData['name'] ?? 'Unknown Item';
          }
        } catch (e) {
          debugPrint('Error fetching item name for $itemId: $e');
        }
        
        mostViewedWithNames.add({
          'itemId': itemId,
          'itemName': itemName,
          'viewCount': data['viewCount'] ?? 0,
          'category': data['category'],
        });
      }
      
      analytics['mostViewed'] = mostViewedWithNames;

      // Get most clicked items
      final mostClicked = await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .orderBy('clickCount', descending: true)
          .limit(10)
          .get();
      
      // Fetch item names for most clicked items
      final mostClickedWithNames = <Map<String, dynamic>>[];
      for (final doc in mostClicked.docs) {
        final data = doc.data();
        final itemId = doc.id;
        
        // Get item name from store items collection
        String itemName = 'Unknown Item';
        try {
          final itemDoc = await _firestore.collection('store_items').doc(itemId).get();
          if (itemDoc.exists) {
            final itemData = itemDoc.data() as Map<String, dynamic>;
            itemName = itemData['name'] ?? 'Unknown Item';
          }
        } catch (e) {
          debugPrint('Error fetching item name for $itemId: $e');
        }
        
        mostClickedWithNames.add({
          'itemId': itemId,
          'itemName': itemName,
          'clickCount': data['clickCount'] ?? 0,
          'category': data['category'],
        });
      }
      
      analytics['mostClicked'] = mostClickedWithNames;

      // Get category popularity
      final categoryStats = await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .get();
      
      analytics['categoryPopularity'] = categoryStats.docs.map((doc) {
        final data = doc.data();
        return {
          'category': doc.id,
          'viewCount': data['viewCount'] ?? 0,
        };
      }).toList();

      // Get total users with interests
      final userInterests = await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .get();
      
      analytics['totalActiveUsers'] = userInterests.docs.length;

      debugPrint('Analytics: Data loaded - mostViewed: ${analytics['mostViewed']?.length ?? 0}, mostClicked: ${analytics['mostClicked']?.length ?? 0}, categories: ${analytics['categoryPopularity']?.length ?? 0}, users: ${analytics['totalActiveUsers']}');

      return analytics;
    } catch (e) {
      debugPrint('Error getting analytics data: $e');
      return {};
    }
  }

  /// Generate sample analytics data for testing
  Future<void> generateSampleData() async {
    try {
      debugPrint('Analytics: Generating sample data...');
      
      // Sample item views
      await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .doc('sample_item_1')
          .set({
        'viewCount': 15,
        'lastViewed': FieldValue.serverTimestamp(),
        'category': 'food',
      });

      await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .doc('sample_item_2')
          .set({
        'viewCount': 12,
        'lastViewed': FieldValue.serverTimestamp(),
        'category': 'toys',
      });

      await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .doc('sample_item_3')
          .set({
        'viewCount': 8,
        'lastViewed': FieldValue.serverTimestamp(),
        'category': 'grooming',
      });

      // Sample item clicks
      await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .doc('sample_item_1')
          .set({
        'clickCount': 5,
        'lastClicked': FieldValue.serverTimestamp(),
        'category': 'food',
      });

      await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .doc('sample_item_2')
          .set({
        'clickCount': 3,
        'lastClicked': FieldValue.serverTimestamp(),
        'category': 'toys',
      });

      // Sample category popularity
      await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .doc('food')
          .set({
        'viewCount': 25,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .doc('toys')
          .set({
        'viewCount': 18,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .doc('grooming')
          .set({
        'viewCount': 12,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Sample user interests
      await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc('sample_user_1')
          .set({
        'interests': ['food', 'toys'],
        'lastActivity': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc('sample_user_2')
          .set({
        'interests': ['grooming', 'health'],
        'lastActivity': FieldValue.serverTimestamp(),
      });

      debugPrint('Analytics: Sample data generated successfully!');
    } catch (e) {
      debugPrint('Error generating sample data: $e');
    }
  }

  /// Get user-specific recommendations based on their interests
  Future<List<String>> getUserRecommendations(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('analytics')
          .doc('user_interests')
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>;
      final interests = List<String>.from(data['interests'] ?? []);
      final favoriteCategories = List<String>.from(data['favoriteCategories'] ?? []);
      
      // Combine interests and favorite categories
      final allInterests = {...interests, ...favoriteCategories};
      
      // Get popular items from user's interested categories
      final recommendations = <String>[];
      for (final category in allInterests) {
        final categoryItems = await _firestore
            .collection('analytics')
            .doc('item_views')
            .collection('items')
            .where('category', isEqualTo: category.toLowerCase())
            .orderBy('viewCount', descending: true)
            .limit(3)
            .get();
        
        recommendations.addAll(categoryItems.docs.map((doc) => doc.id));
      }
      
      return recommendations.take(10).toList();
    } catch (e) {
      debugPrint('Error getting user recommendations: $e');
      return [];
    }
  }

  /// Load analytics data from Firestore
  Future<void> loadAnalyticsData() async {
    try {
      // Load item view counts
      final viewCounts = await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .get();
      
      _itemViewCounts.clear();
      for (final doc in viewCounts.docs) {
        final data = doc.data();
        _itemViewCounts[doc.id] = data['viewCount'] ?? 0;
      }

      // Load item click counts
      final clickCounts = await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .get();
      
      _itemClickCounts.clear();
      for (final doc in clickCounts.docs) {
        final data = doc.data();
        _itemClickCounts[doc.id] = data['clickCount'] ?? 0;
      }

      // Load category popularity
      final categoryStats = await _firestore
          .collection('analytics')
          .doc('category_popularity')
          .collection('categories')
          .get();
      
      _categoryPopularity.clear();
      for (final doc in categoryStats.docs) {
        final data = doc.data();
        _categoryPopularity[doc.id] = (data['viewCount'] ?? 0).toDouble();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    }
  }

  String _getCategoryName(StoreCategory category) {
    switch (category) {
      case StoreCategory.food:
        return 'Food';
      case StoreCategory.grooming:
        return 'Grooming';
      case StoreCategory.toys:
        return 'Toys';
      case StoreCategory.health:
        return 'Health';
      case StoreCategory.accessories:
        return 'Accessories';
      case StoreCategory.other:
        return 'Other';
    }
  }
}
