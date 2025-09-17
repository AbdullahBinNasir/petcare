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
        
        // Try to get item name from analytics data first (faster)
        String itemName = data['itemName'];
        
        // If not available in analytics, fall back to store items collection
        if (itemName == null || itemName.isEmpty || itemName == 'Unknown Item') {
          itemName = await getItemName(itemId);
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
        
        // Try to get item name from analytics data first (faster)
        String itemName = data['itemName'];
        
        // If not available in analytics, fall back to store items collection
        if (itemName == null || itemName.isEmpty || itemName == 'Unknown Item') {
          itemName = await getItemName(itemId);
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
      
      // Get actual store items to use their real IDs
      final storeItems = await _firestore
          .collection('store_items')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();
      
      if (storeItems.docs.isEmpty) {
        // If no store items exist, create some sample ones first
        await _createSampleStoreItems();
        // Retry getting the items
        final newStoreItems = await _firestore
            .collection('store_items')
            .where('isActive', isEqualTo: true)
            .limit(10)
            .get();
        
        if (newStoreItems.docs.isNotEmpty) {
          await _generateAnalyticsForItems(newStoreItems.docs);
        }
      } else {
        await _generateAnalyticsForItems(storeItems.docs);
      }

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
  
  /// Generate analytics data for a list of actual store items
  Future<void> _generateAnalyticsForItems(List<QueryDocumentSnapshot> items) async {
    try {
      debugPrint('Generating analytics for ${items.length} real store items...');
      
      for (int i = 0; i < items.length && i < 5; i++) {
        final doc = items[i];
        final itemData = doc.data() as Map<String, dynamic>;
        final itemId = doc.id;
        final category = itemData['category'] ?? 'other';
        final itemName = itemData['name'] ?? 'Unknown Item';
        
        debugPrint('Creating analytics for item: $itemName (ID: $itemId, Category: $category)');
        
        // Generate sample view counts (decreasing order)
        final viewCount = 15 - (i * 2);
        await _firestore
            .collection('analytics')
            .doc('item_views')
            .collection('items')
            .doc(itemId)
            .set({
          'viewCount': viewCount,
          'lastViewed': FieldValue.serverTimestamp(),
          'category': category,
          'itemName': itemName, // Store name for easier lookup
        });
        
        // Generate sample click counts (about 1/3 of view counts)
        final clickCount = (viewCount / 3).round();
        await _firestore
            .collection('analytics')
            .doc('item_clicks')
            .collection('items')
            .doc(itemId)
            .set({
          'clickCount': clickCount,
          'lastClicked': FieldValue.serverTimestamp(),
          'category': category,
          'itemName': itemName, // Store name for easier lookup
        });
      }
    } catch (e) {
      debugPrint('Error generating analytics for items: $e');
    }
  }

  /// Create sample store items for analytics testing
  Future<void> _createSampleStoreItems() async {
    try {
      // Check if any store items exist
      final existingItems = await _firestore
          .collection('store_items')
          .limit(1)
          .get();
      
      if (existingItems.docs.isNotEmpty) {
        debugPrint('Store items already exist, skipping sample creation');
        return;
      }

      debugPrint('Creating sample store items...');
      
      // Create sample store items using add() to get auto-generated IDs
      final sampleItems = [
        {
          'name': 'Premium Dog Food',
          'description': 'High-quality nutrition for adult dogs with essential vitamins and minerals',
          'price': 29.99,
          'category': 'food',
          'brand': 'PetCare Pro',
          'isActive': true,
          'isInStock': true,
          'stockQuantity': 50,
          'imageUrls': [],
          'externalUrl': '',
          'specifications': {'Weight': '5kg', 'Age': 'Adult', 'Ingredients': 'Chicken, Rice, Vegetables'},
          'tags': ['premium', 'nutrition', 'adult'],
          'rating': 4.5,
          'reviewCount': 25,
          'clickCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Interactive Cat Toy',
          'description': 'Engaging electronic toy to keep your cat mentally stimulated and active',
          'price': 15.99,
          'category': 'toys',
          'brand': 'Feline Fun',
          'isActive': true,
          'isInStock': true,
          'stockQuantity': 30,
          'imageUrls': [],
          'externalUrl': '',
          'specifications': {'Material': 'Plastic', 'Batteries': '2 AA', 'Size': 'Medium'},
          'tags': ['interactive', 'electronic', 'mental stimulation'],
          'rating': 4.2,
          'reviewCount': 18,
          'clickCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Complete Grooming Kit',
          'description': 'Professional-grade grooming tools for maintaining your pet\'s coat',
          'price': 45.99,
          'category': 'grooming',
          'brand': 'GroomMaster',
          'isActive': true,
          'isInStock': true,
          'stockQuantity': 20,
          'imageUrls': [],
          'externalUrl': '',
          'specifications': {'Includes': 'Brush, Comb, Nail Clippers, Scissors', 'Material': 'Stainless Steel'},
          'tags': ['professional', 'complete set', 'grooming'],
          'rating': 4.8,
          'reviewCount': 32,
          'clickCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Healthy Pet Treats',
          'description': 'Natural, organic treats perfect for training and rewards',
          'price': 8.99,
          'category': 'food',
          'brand': 'Nature\'s Best',
          'isActive': true,
          'isInStock': true,
          'stockQuantity': 100,
          'imageUrls': [],
          'externalUrl': '',
          'specifications': {'Weight': '200g', 'Ingredients': 'Organic Chicken, Sweet Potato'},
          'tags': ['organic', 'treats', 'training'],
          'rating': 4.3,
          'reviewCount': 45,
          'clickCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Cozy Pet Bed',
          'description': 'Ultra-comfortable orthopedic bed for better pet sleep',
          'price': 39.99,
          'category': 'accessories',
          'brand': 'ComfortPet',
          'isActive': true,
          'isInStock': true,
          'stockQuantity': 15,
          'imageUrls': [],
          'externalUrl': '',
          'specifications': {'Size': 'Medium', 'Material': 'Memory Foam', 'Washable': 'Yes'},
          'tags': ['comfort', 'orthopedic', 'sleep'],
          'rating': 4.6,
          'reviewCount': 28,
          'clickCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add each sample item to Firestore using add() for auto-generated IDs
      for (final item in sampleItems) {
        await _firestore
            .collection('store_items')
            .add(item);
      }
      
      // Add a small delay to ensure items are created before generating analytics
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Sample store items created successfully with auto-generated IDs!');
    } catch (e) {
      debugPrint('Error creating sample store items: $e');
    }
  }

  /// Get item name from store items collection with fallback to analytics data
  Future<String> getItemName(String itemId) async {
    try {
      // First try to get from store items
      final storeDoc = await _firestore
          .collection('store_items')
          .doc(itemId)
          .get();
      
      if (storeDoc.exists) {
        final data = storeDoc.data() as Map<String, dynamic>;
        final itemName = data['name'] ?? 'Unknown Item';
        debugPrint('Found item name from store: $itemName for ID: $itemId');
        return itemName;
      }
      
      // Fallback: try to get from analytics data (which now stores itemName)
      final analyticsViews = await _firestore
          .collection('analytics')
          .doc('item_views')
          .collection('items')
          .doc(itemId)
          .get();
      
      if (analyticsViews.exists) {
        final data = analyticsViews.data() as Map<String, dynamic>;
        final itemName = data['itemName'];
        if (itemName != null && itemName.isNotEmpty) {
          debugPrint('Found item name from analytics: $itemName for ID: $itemId');
          return itemName;
        }
      }
      
      // If still not found, try analytics clicks data
      final analyticsClicks = await _firestore
          .collection('analytics')
          .doc('item_clicks')
          .collection('items')
          .doc(itemId)
          .get();
      
      if (analyticsClicks.exists) {
        final data = analyticsClicks.data() as Map<String, dynamic>;
        final itemName = data['itemName'];
        if (itemName != null && itemName.isNotEmpty) {
          debugPrint('Found item name from analytics clicks: $itemName for ID: $itemId');
          return itemName;
        }
      }
      
      debugPrint('No item name found for ID: $itemId');
      return 'Unknown Item';
    } catch (e) {
      debugPrint('Error getting item name for ID $itemId: $e');
      return 'Unknown Item';
    }
  }
  
  /// Get all item names for a list of item IDs efficiently
  Future<Map<String, String>> getItemNames(List<String> itemIds) async {
    final Map<String, String> itemNames = {};
    
    if (itemIds.isEmpty) return itemNames;
    
    try {
      // Batch get from store items first
      final storeQuery = await _firestore
          .collection('store_items')
          .where(FieldPath.documentId, whereIn: itemIds.take(10).toList()) // Firestore limit
          .get();
      
      for (final doc in storeQuery.docs) {
        final data = doc.data();
        final name = data['name'];
        if (name != null && name.isNotEmpty) {
          itemNames[doc.id] = name;
        }
      }
      
      // For remaining items without names, try analytics data
      final missingIds = itemIds.where((id) => !itemNames.containsKey(id)).toList();
      
      if (missingIds.isNotEmpty) {
        // Try analytics views
        for (final itemId in missingIds.take(5)) { // Limit to avoid too many requests
          final analyticsDoc = await _firestore
              .collection('analytics')
              .doc('item_views')
              .collection('items')
              .doc(itemId)
              .get();
          
          if (analyticsDoc.exists) {
            final data = analyticsDoc.data() as Map<String, dynamic>;
            final itemName = data['itemName'];
            if (itemName != null && itemName.isNotEmpty) {
              itemNames[itemId] = itemName;
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error batch getting item names: $e');
    }
    
    // Fill in any remaining missing names
    for (final itemId in itemIds) {
      if (!itemNames.containsKey(itemId)) {
        itemNames[itemId] = 'Unknown Item';
      }
    }
    
    return itemNames;
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
