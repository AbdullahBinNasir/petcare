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
}
