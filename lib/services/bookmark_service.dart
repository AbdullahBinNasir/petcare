import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark_model.dart';
import '../models/blog_post_model.dart';

class BookmarkService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<BookmarkModel> _bookmarks = [];
  List<BookmarkModel> _filteredBookmarks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'recent'; // recent, oldest, read, unread, progress
  String _filterBy = 'all'; // all, read, unread, in_progress

  List<BookmarkModel> get bookmarks => _filteredBookmarks;
  List<BookmarkModel> get allBookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  String get filterBy => _filterBy;

  // Get bookmarks for a specific user
  Future<void> loadUserBookmarks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .orderBy('bookmarkedAt', descending: true)
          .get();

      _bookmarks = querySnapshot.docs
          .map((doc) => BookmarkModel.fromFirestore(doc))
          .toList();

      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading user bookmarks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a blog post to bookmarks
  Future<bool> addBookmark(String userId, BlogPostModel post) async {
    try {
      debugPrint('Adding bookmark for user: $userId, post: ${post.id}');
      debugPrint('Post title: ${post.title}');
      debugPrint('Post excerpt: ${post.excerpt}');
      debugPrint('Post category: ${post.category}');
      debugPrint('Post tags: ${post.tags}');
      
      // Check if already bookmarked
      final existingBookmark = _bookmarks.firstWhere(
        (bookmark) => bookmark.userId == userId && bookmark.postId == post.id,
        orElse: () => BookmarkModel(
          id: '',
          userId: '',
          postId: '',
          postTitle: '',
          postExcerpt: '',
          postCategory: '',
          postReadTime: 0,
          bookmarkedAt: DateTime.now(),
        ),
      );

      if (existingBookmark.id.isNotEmpty) {
        debugPrint('Bookmark already exists for this post');
        return false; // Already bookmarked
      }

      final bookmark = BookmarkModel(
        id: '', // Will be set by Firestore
        userId: userId,
        postId: post.id,
        postTitle: post.title,
        postExcerpt: post.excerpt,
        postImageUrl: post.featuredImageUrl,
        postCategory: post.category.toString().split('.').last,
        postTags: post.tags,
        postReadTime: post.readTime,
        bookmarkedAt: DateTime.now(),
      );

      debugPrint('Created bookmark model, converting to Firestore...');
      final bookmarkData = bookmark.toFirestore();
      debugPrint('Bookmark data: $bookmarkData');

      debugPrint('Adding to Firestore...');
      final docRef = await _firestore.collection('bookmarks').add(bookmarkData);
      debugPrint('Bookmark added to Firebase with ID: ${docRef.id}');
      
      // Update local list
      final newBookmark = bookmark.copyWith(id: docRef.id);
      _bookmarks.insert(0, newBookmark);
      _applyFiltersAndSort();
      notifyListeners();
      debugPrint('Bookmark added locally, total bookmarks: ${_bookmarks.length}');

      return true;
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // Remove a bookmark
  Future<bool> removeBookmark(String userId, String postId) async {
    try {
      final bookmarkIndex = _bookmarks.indexWhere(
        (bookmark) => bookmark.userId == userId && bookmark.postId == postId,
      );

      if (bookmarkIndex == -1) return false;

      final bookmark = _bookmarks[bookmarkIndex];
      
      await _firestore.collection('bookmarks').doc(bookmark.id).delete();
      
      _bookmarks.removeAt(bookmarkIndex);
      _applyFiltersAndSort();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      return false;
    }
  }

  // Check if a post is bookmarked
  bool isBookmarked(String userId, String postId) {
    final isBookmarked = _bookmarks.any(
      (bookmark) => bookmark.userId == userId && bookmark.postId == postId,
    );
    debugPrint('Checking bookmark for user: $userId, post: $postId, isBookmarked: $isBookmarked, total bookmarks: ${_bookmarks.length}');
    return isBookmarked;
  }

  // Get bookmark for a specific post
  BookmarkModel? getBookmark(String userId, String postId) {
    try {
      return _bookmarks.firstWhere(
        (bookmark) => bookmark.userId == userId && bookmark.postId == postId,
      );
    } catch (e) {
      return null;
    }
  }

  // Update bookmark progress
  Future<void> updateReadProgress(String bookmarkId, int progress) async {
    try {
      await _firestore.collection('bookmarks').doc(bookmarkId).update({
        'readProgress': progress,
        'lastReadAt': FieldValue.serverTimestamp(),
        'isRead': progress >= 100,
      });

      // Update local data
      final bookmarkIndex = _bookmarks.indexWhere((b) => b.id == bookmarkId);
      if (bookmarkIndex != -1) {
        _bookmarks[bookmarkIndex] = _bookmarks[bookmarkIndex].copyWith(
          readProgress: progress,
          lastReadAt: DateTime.now(),
          isRead: progress >= 100,
        );
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error updating read progress: $e');
    }
  }

  // Add notes to bookmark
  Future<void> addNotes(String bookmarkId, String notes) async {
    try {
      await _firestore.collection('bookmarks').doc(bookmarkId).update({
        'notes': notes,
      });

      // Update local data
      final bookmarkIndex = _bookmarks.indexWhere((b) => b.id == bookmarkId);
      if (bookmarkIndex != -1) {
        _bookmarks[bookmarkIndex] = _bookmarks[bookmarkIndex].copyWith(notes: notes);
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error adding notes: $e');
    }
  }

  // Search bookmarks
  void searchBookmarks(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  // Filter by read status
  void filterByReadStatus(String status) {
    _filterBy = status;
    _applyFiltersAndSort();
  }

  // Sort bookmarks
  void sortBookmarks(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredBookmarks = List.from(_bookmarks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredBookmarks = _filteredBookmarks.where((bookmark) {
        return bookmark.postTitle.toLowerCase().contains(_searchQuery) ||
               bookmark.postExcerpt.toLowerCase().contains(_searchQuery) ||
               bookmark.postTags.any((tag) => tag.toLowerCase().contains(_searchQuery)) ||
               (bookmark.notes?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'all') {
      _filteredBookmarks = _filteredBookmarks
          .where((bookmark) => bookmark.postCategory == _selectedCategory)
          .toList();
    }

    // Apply read status filter
    if (_filterBy != 'all') {
      _filteredBookmarks = _filteredBookmarks.where((bookmark) {
        switch (_filterBy) {
          case 'read':
            return bookmark.isRead;
          case 'unread':
            return !bookmark.isRead && bookmark.readProgress == 0;
          case 'in_progress':
            return !bookmark.isRead && bookmark.readProgress > 0;
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'recent':
        _filteredBookmarks.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
        break;
      case 'oldest':
        _filteredBookmarks.sort((a, b) => a.bookmarkedAt.compareTo(b.bookmarkedAt));
        break;
      case 'read':
        _filteredBookmarks.sort((a, b) {
          if (a.isRead && !b.isRead) return -1;
          if (!a.isRead && b.isRead) return 1;
          return b.bookmarkedAt.compareTo(a.bookmarkedAt);
        });
        break;
      case 'unread':
        _filteredBookmarks.sort((a, b) {
          if (!a.isRead && b.isRead) return -1;
          if (a.isRead && !b.isRead) return 1;
          return b.bookmarkedAt.compareTo(a.bookmarkedAt);
        });
        break;
      case 'progress':
        _filteredBookmarks.sort((a, b) => b.readProgress.compareTo(a.readProgress));
        break;
      case 'title':
        _filteredBookmarks.sort((a, b) => a.postTitle.compareTo(b.postTitle));
        break;
    }

    notifyListeners();
  }

  // Get reading statistics
  Map<String, dynamic> getReadingStats() {
    final totalBookmarks = _bookmarks.length;
    final readBookmarks = _bookmarks.where((b) => b.isRead).length;
    final inProgressBookmarks = _bookmarks.where((b) => !b.isRead && b.readProgress > 0).length;
    final unreadBookmarks = _bookmarks.where((b) => !b.isRead && b.readProgress == 0).length;
    
    final totalReadTime = _bookmarks.fold<int>(0, (sum, b) => sum + b.postReadTime);
    final readReadTime = _bookmarks
        .where((b) => b.isRead)
        .fold<int>(0, (sum, b) => sum + b.postReadTime);

    return {
      'totalBookmarks': totalBookmarks,
      'readBookmarks': readBookmarks,
      'inProgressBookmarks': inProgressBookmarks,
      'unreadBookmarks': unreadBookmarks,
      'totalReadTime': totalReadTime,
      'readReadTime': readReadTime,
      'completionRate': totalBookmarks > 0 ? (readBookmarks / totalBookmarks * 100).round() : 0,
    };
  }

  // Get bookmarks by category
  Map<String, int> getBookmarksByCategory() {
    final Map<String, int> categoryCount = {};
    for (final bookmark in _bookmarks) {
      categoryCount[bookmark.postCategory] = (categoryCount[bookmark.postCategory] ?? 0) + 1;
    }
    return categoryCount;
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'all';
    _sortBy = 'recent';
    _filterBy = 'all';
    _applyFiltersAndSort();
  }

  // Delete bookmark
  Future<bool> deleteBookmark(String bookmarkId) async {
    try {
      await _firestore.collection('bookmarks').doc(bookmarkId).delete();
      
      _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting bookmark: $e');
      return false;
    }
  }

  // Bulk delete bookmarks
  Future<int> bulkDeleteBookmarks(List<String> bookmarkIds) async {
    int deletedCount = 0;
    
    for (final bookmarkId in bookmarkIds) {
      try {
        await _firestore.collection('bookmarks').doc(bookmarkId).delete();
        _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
        deletedCount++;
      } catch (e) {
        debugPrint('Error deleting bookmark $bookmarkId: $e');
      }
    }
    
    _applyFiltersAndSort();
    return deletedCount;
  }

  // Export bookmarks (for offline reading)
  List<Map<String, dynamic>> exportBookmarks() {
    return _bookmarks.map((bookmark) => {
      'id': bookmark.id,
      'postId': bookmark.postId,
      'title': bookmark.postTitle,
      'excerpt': bookmark.postExcerpt,
      'category': bookmark.postCategory,
      'tags': bookmark.postTags,
      'readTime': bookmark.postReadTime,
      'bookmarkedAt': bookmark.bookmarkedAt.toIso8601String(),
      'isRead': bookmark.isRead,
      'readProgress': bookmark.readProgress,
      'notes': bookmark.notes,
    }).toList();
  }
}
