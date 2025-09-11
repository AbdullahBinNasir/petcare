import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item_model.dart';

class StoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<StoreItemModel> _storeItems = [];
  List<StoreItemModel> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';
  StoreCategory? _selectedCategory;
  String _sortBy = 'name'; // name, price_low, price_high, rating, popularity
  
  // User interaction tracking
  Map<String, int> _userClicks = {};
  Map<String, List<String>> _userFavorites = {};

  List<StoreItemModel> get storeItems => _filteredItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  StoreCategory? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  Future<void> loadStoreItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('store_items')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _storeItems = querySnapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();

      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading store items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchItems(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void filterByCategory(StoreCategory? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void sortItems(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
  }

  // Advanced filtering options
  void filterByPriceRange(double minPrice, double maxPrice) {
    _filteredItems = _storeItems.where((item) {
      return item.price >= minPrice && item.price <= maxPrice;
    }).toList();
    _applySort();
  }

  void filterByBrand(String brand) {
    _filteredItems = _storeItems.where((item) {
      return item.brand.toLowerCase().contains(brand.toLowerCase());
    }).toList();
    _applySort();
  }

  void filterByRating(double minRating) {
    _filteredItems = _storeItems.where((item) {
      return (item.rating ?? 0) >= minRating;
    }).toList();
    _applySort();
  }

  void filterInStock() {
    _filteredItems = _storeItems.where((item) => item.isInStock).toList();
    _applySort();
  }

  void _applyFiltersAndSort() {
    _filteredItems = List.from(_storeItems);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredItems = _filteredItems.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
               item.description.toLowerCase().contains(_searchQuery) ||
               item.brand.toLowerCase().contains(_searchQuery) ||
               item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      _filteredItems = _filteredItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    _applySort();
  }

  void _applySort() {
    // Apply sorting
    switch (_sortBy) {
      case 'name':
        _filteredItems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        _filteredItems.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _filteredItems.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        _filteredItems.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'popularity':
        _filteredItems.sort((a, b) => (b.reviewCount + (_userClicks[b.id] ?? 0)).compareTo(a.reviewCount + (_userClicks[a.id] ?? 0)));
        break;
      case 'newest':
        _filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    notifyListeners();
  }

  Future<void> trackItemClick(String itemId, String userId) async {
    try {
      // Update local tracking
      _userClicks[itemId] = (_userClicks[itemId] ?? 0) + 1;

      // Update in Firestore
      await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('item_clicks')
          .doc(itemId)
          .set({
        'clicks': FieldValue.increment(1),
        'lastClicked': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update item popularity
      await _firestore
          .collection('store_items')
          .doc(itemId)
          .update({
        'clickCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error tracking item click: $e');
    }
  }

  // Track external purchase link clicks
  Future<void> trackExternalPurchaseClick(String itemId, String userId) async {
    try {
      // Track external purchase clicks separately
      await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('purchase_clicks')
          .doc(itemId)
          .set({
        'clicks': FieldValue.increment(1),
        'lastClicked': FieldValue.serverTimestamp(),
        'clickType': 'external_purchase',
      }, SetOptions(merge: true));

      // Update item purchase interest
      await _firestore
          .collection('store_items')
          .doc(itemId)
          .update({
        'purchaseClickCount': FieldValue.increment(1),
      });

      // Track for analytics
      await _firestore.collection('analytics').add({
        'eventType': 'external_purchase_click',
        'itemId': itemId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking external purchase click: $e');
    }
  }

  // Get user interest analytics for specific user
  Future<Map<String, dynamic>> getUserInterestAnalytics(String userId) async {
    try {
      final clicksSnapshot = await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('item_clicks')
          .orderBy('clicks', descending: true)
          .limit(10)
          .get();

      final purchaseClicksSnapshot = await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('purchase_clicks')
          .orderBy('clicks', descending: true)
          .limit(10)
          .get();

      // Get category preferences
      final categoryPreferences = <String, int>{};
      for (final doc in clicksSnapshot.docs) {
        final item = _storeItems.firstWhere(
          (item) => item.id == doc.id,
          orElse: () => _storeItems.first,
        );
        final category = item.category.toString().split('.').last;
        categoryPreferences[category] = (categoryPreferences[category] ?? 0) + (doc.data()['clicks'] as int);
      }

      return {
        'topClickedItems': clicksSnapshot.docs.map((doc) => {
          'itemId': doc.id,
          'clicks': doc.data()['clicks'],
          'lastClicked': doc.data()['lastClicked'],
        }).toList(),
        'topPurchaseIntents': purchaseClicksSnapshot.docs.map((doc) => {
          'itemId': doc.id,
          'clicks': doc.data()['clicks'],
          'lastClicked': doc.data()['lastClicked'],
        }).toList(),
        'categoryPreferences': categoryPreferences,
      };
    } catch (e) {
      debugPrint('Error getting user interest analytics: $e');
      return {};
    }
  }

  Future<void> toggleFavorite(String itemId, String userId) async {
    try {
      final userFavorites = _userFavorites[userId] ?? [];
      final isFavorite = userFavorites.contains(itemId);

      if (isFavorite) {
        userFavorites.remove(itemId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('store_items')
            .update({
          'items': FieldValue.arrayRemove([itemId]),
        });
      } else {
        userFavorites.add(itemId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('store_items')
            .set({
          'items': FieldValue.arrayUnion([itemId]),
        }, SetOptions(merge: true));
      }

      _userFavorites[userId] = userFavorites;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> loadUserFavorites(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('store_items')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userFavorites[userId] = List<String>.from(data['items'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user favorites: $e');
    }
  }

  bool isItemFavorite(String itemId, String userId) {
    return _userFavorites[userId]?.contains(itemId) ?? false;
  }

  List<StoreItemModel> getFavoriteItems(String userId) {
    final favoriteIds = _userFavorites[userId] ?? [];
    return _storeItems.where((item) => favoriteIds.contains(item.id)).toList();
  }

  // Admin functions
  Future<void> addStoreItem(StoreItemModel item) async {
    try {
      await _firestore.collection('store_items').add(item.toFirestore());
      await loadStoreItems(); // Refresh the list
    } catch (e) {
      debugPrint('Error adding store item: $e');
      rethrow;
    }
  }

  Future<void> updateStoreItem(StoreItemModel item) async {
    try {
      await _firestore
          .collection('store_items')
          .doc(item.id)
          .update(item.toFirestore());
      await loadStoreItems(); // Refresh the list
    } catch (e) {
      debugPrint('Error updating store item: $e');
      rethrow;
    }
  }

  Future<void> deleteStoreItem(String itemId) async {
    try {
      await _firestore
          .collection('store_items')
          .doc(itemId)
          .update({'isActive': false});
      await loadStoreItems(); // Refresh the list
    } catch (e) {
      debugPrint('Error deleting store item: $e');
      rethrow;
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'name';
    _applyFiltersAndSort();
  }

  // Get popular items based on clicks and purchases
  List<StoreItemModel> getPopularItems({int limit = 10}) {
    final itemsWithPopularity = _storeItems.map((item) {
      final clicks = _userClicks[item.id] ?? 0;
      final reviewWeight = item.reviewCount * 2; // Reviews are worth more than clicks
      final ratingWeight = ((item.rating ?? 0) * 10).round();
      return {
        'item': item,
        'popularity': clicks + reviewWeight + ratingWeight,
      };
    }).toList();

    itemsWithPopularity.sort((a, b) => (b['popularity'] as int).compareTo(a['popularity'] as int));
    
    return itemsWithPopularity
        .take(limit)
        .map((data) => data['item'] as StoreItemModel)
        .toList();
  }

  // Get recommendations based on user behavior
  List<StoreItemModel> getRecommendedItems(String userId, {int limit = 5}) {
    final userFavorites = _userFavorites[userId] ?? [];
    if (userFavorites.isEmpty) {
      return getPopularItems(limit: limit);
    }

    // Find categories user likes
    final favoriteCategories = <StoreCategory>{};
    for (final itemId in userFavorites) {
      final item = _storeItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => _storeItems.first,
      );
      favoriteCategories.add(item.category);
    }

    // Recommend items from favorite categories
    final recommendations = _storeItems
        .where((item) => favoriteCategories.contains(item.category) && !userFavorites.contains(item.id))
        .take(limit)
        .toList();

    return recommendations;
  }
}
