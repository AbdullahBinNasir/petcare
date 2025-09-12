import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item_model.dart';
import 'analytics_service.dart';

class StoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AnalyticsService? _analyticsService;
  
  List<StoreItemModel> _storeItems = [];
  List<StoreItemModel> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';
  StoreCategory? _selectedCategory;
  String _sortBy = 'name'; // name, price_low, price_high, rating, popularity
  
  // User interaction tracking
  Map<String, int> _userClicks = {};
  Map<String, List<String>> _userFavorites = {};

  void setAnalyticsService(AnalyticsService analyticsService) {
    _analyticsService = analyticsService;
    debugPrint('Analytics service connected to StoreService');
  }

  Future<void> trackItemView(String itemId, String userId) async {
    try {
      // Find the item to get its category
      final item = _storeItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => StoreItemModel(
          id: itemId,
          name: '',
          description: '',
          price: 0,
          category: StoreCategory.other,
          brand: '',
          externalUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Track with analytics service
      _analyticsService?.trackItemView(itemId, userId, item.category);
    } catch (e) {
      debugPrint('Error tracking item view: $e');
    }
  }

  List<StoreItemModel> get storeItems => _filteredItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  StoreCategory? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  Future<void> loadStoreItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try with orderBy, if it fails, try without
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('store_items')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        debugPrint('OrderBy query failed, trying without orderBy: $e');
        // If orderBy fails (likely due to missing composite index), try without it
        querySnapshot = await _firestore
            .collection('store_items')
            .where('isActive', isEqualTo: true)
            .get();
      }

      _storeItems = querySnapshot.docs
          .map((doc) {
            try {
              return StoreItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing document ${doc.id}: $e');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<StoreItemModel>()
          .toList();

      debugPrint('Loaded ${_storeItems.length} store items from Firestore');
      for (var item in _storeItems) {
        debugPrint('Item: ${item.name}, isActive: ${item.isActive}, createdAt: ${item.createdAt}');
      }

      // Sort manually if orderBy didn't work
      _storeItems.sort((a, b) {
        try {
          return b.createdAt.compareTo(a.createdAt);
        } catch (e) {
          debugPrint('Error sorting by createdAt: $e');
          return 0; // Keep original order if sorting fails
        }
      });

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
        _filteredItems.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    notifyListeners();
  }

  Future<void> trackItemClick(String itemId, String userId) async {
    try {
      // Update local tracking
      _userClicks[itemId] = (_userClicks[itemId] ?? 0) + 1;

      // Find the item to get its category
      final item = _storeItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => StoreItemModel(
          id: itemId,
          name: '',
          description: '',
          price: 0,
          category: StoreCategory.other,
          brand: '',
          externalUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Track with analytics service
      _analyticsService?.trackItemClick(itemId, userId, item.category);

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

  Future<void> toggleFavorite(String itemId, String userId) async {
    try {
      final userFavorites = _userFavorites[userId] ?? [];
      final isFavorite = userFavorites.contains(itemId);

      // Find the item to get its category
      final item = _storeItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => StoreItemModel(
          id: itemId,
          name: '',
          description: '',
          price: 0,
          category: StoreCategory.other,
          brand: '',
          externalUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Track with analytics service
      _analyticsService?.trackFavoriteAction(itemId, userId, !isFavorite, item.category);

      if (isFavorite) {
        // Remove from favorites
        userFavorites.remove(itemId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('store_items')
            .update({
          'items': FieldValue.arrayRemove([itemId]),
        });
        debugPrint('Removed item $itemId from favorites for user $userId');
      } else {
        // Add to favorites
        userFavorites.add(itemId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('store_items')
            .set({
          'items': FieldValue.arrayUnion([itemId]),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Added item $itemId to favorites for user $userId');
      }

      _userFavorites[userId] = userFavorites;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow; // Re-throw to allow UI to handle the error
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

  // Get favorite items count
  int getFavoriteItemsCount(String userId) {
    return _userFavorites[userId]?.length ?? 0;
  }

  // Check if user has any favorites
  bool hasFavorites(String userId) {
    return getFavoriteItemsCount(userId) > 0;
  }

  // Get favorite items by category
  List<StoreItemModel> getFavoriteItemsByCategory(String userId, StoreCategory category) {
    final favoriteItems = getFavoriteItems(userId);
    return favoriteItems.where((item) => item.category == category).toList();
  }

  // Clear all favorites for a user
  Future<void> clearAllFavorites(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('store_items')
          .delete();
      
      _userFavorites[userId] = [];
      notifyListeners();
      debugPrint('Cleared all favorites for user $userId');
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
      rethrow;
    }
  }

  // Remove specific item from favorites
  Future<void> removeFromFavorites(String itemId, String userId) async {
    try {
      final userFavorites = _userFavorites[userId] ?? [];
      if (userFavorites.contains(itemId)) {
        await toggleFavorite(itemId, userId);
      }
    } catch (e) {
      debugPrint('Error removing item from favorites: $e');
      rethrow;
    }
  }

  // Admin functions
  Future<void> addStoreItem(StoreItemModel item) async {
    try {
      debugPrint('Adding store item: ${item.name}, isActive: ${item.isActive}');
      final docRef = await _firestore.collection('store_items').add(item.toFirestore());
      debugPrint('Store item added with ID: ${docRef.id}');
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

  // Debug method to load all items without filters
  Future<void> loadAllStoreItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('store_items')
          .get();

      _storeItems = querySnapshot.docs
          .map((doc) {
            try {
              return StoreItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing document ${doc.id}: $e');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<StoreItemModel>()
          .toList();

      debugPrint('Loaded ALL ${_storeItems.length} store items from Firestore (no filters)');
      for (var item in _storeItems) {
        debugPrint('Item: ${item.name}, isActive: ${item.isActive}, createdAt: ${item.createdAt}');
      }

      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading all store items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
