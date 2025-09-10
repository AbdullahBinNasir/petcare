import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post_model.dart';

class BlogService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<BlogPostModel> _blogPosts = [];
  List<BlogPostModel> _filteredPosts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  BlogCategory? _selectedCategory;
  String _sortBy = 'recent'; // recent, popular, oldest
  
  // User interaction tracking
  Map<String, List<String>> _userFavorites = {};

  List<BlogPostModel> get blogPosts => _filteredPosts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  BlogCategory? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  Future<void> loadBlogPosts({bool publishedOnly = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      Query query = _firestore.collection('blog_posts');
      
      if (publishedOnly) {
        query = query.where('isPublished', isEqualTo: true);
      }
      
      final querySnapshot = await query
          .orderBy('publishedAt', descending: true)
          .get();

      _blogPosts = querySnapshot.docs
          .map((doc) => BlogPostModel.fromFirestore(doc))
          .toList();

      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading blog posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchPosts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void filterByCategory(BlogCategory? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void sortPosts(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredPosts = List.from(_blogPosts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredPosts = _filteredPosts.where((post) {
        return post.title.toLowerCase().contains(_searchQuery) ||
               post.excerpt.toLowerCase().contains(_searchQuery) ||
               post.content.toLowerCase().contains(_searchQuery) ||
               post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      _filteredPosts = _filteredPosts
          .where((post) => post.category == _selectedCategory)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'recent':
        _filteredPosts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case 'popular':
        _filteredPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'oldest':
        _filteredPosts.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
        break;
      case 'likes':
        _filteredPosts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
    }

    notifyListeners();
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'viewCount': FieldValue.increment(1),
      });

      // Update local data
      final postIndex = _blogPosts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _blogPosts[postIndex] = _blogPosts[postIndex].copyWith(
          viewCount: _blogPosts[postIndex].viewCount + 1,
        );
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      final userLikesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('liked_posts')
          .doc(postId);

      final userLikeDoc = await userLikesRef.get();
      final isLiked = userLikeDoc.exists;

      if (isLiked) {
        // Unlike
        await userLikesRef.delete();
        await _firestore
            .collection('blog_posts')
            .doc(postId)
            .update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await userLikesRef.set({
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _firestore
            .collection('blog_posts')
            .doc(postId)
            .update({
          'likeCount': FieldValue.increment(1),
        });
      }

      // Update local data
      final postIndex = _blogPosts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _blogPosts[postIndex] = _blogPosts[postIndex].copyWith(
          likeCount: _blogPosts[postIndex].likeCount + (isLiked ? -1 : 1),
        );
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('liked_posts')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if post is liked: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String postId, String userId) async {
    try {
      final userFavorites = _userFavorites[userId] ?? [];
      final isFavorite = userFavorites.contains(postId);

      if (isFavorite) {
        userFavorites.remove(postId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('blog_posts')
            .update({
          'posts': FieldValue.arrayRemove([postId]),
        });
      } else {
        userFavorites.add(postId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc('blog_posts')
            .set({
          'posts': FieldValue.arrayUnion([postId]),
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
          .doc('blog_posts')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userFavorites[userId] = List<String>.from(data['posts'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user favorites: $e');
    }
  }

  bool isPostFavorite(String postId, String userId) {
    return _userFavorites[userId]?.contains(postId) ?? false;
  }

  List<BlogPostModel> getFavoritePosts(String userId) {
    final favoriteIds = _userFavorites[userId] ?? [];
    return _blogPosts.where((post) => favoriteIds.contains(post.id)).toList();
  }

  Future<BlogPostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore
          .collection('blog_posts')
          .doc(postId)
          .get();

      if (doc.exists) {
        return BlogPostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post by ID: $e');
      return null;
    }
  }

  // Admin functions
  Future<void> createBlogPost(BlogPostModel post) async {
    try {
      await _firestore.collection('blog_posts').add(post.toFirestore());
      await loadBlogPosts(publishedOnly: false); // Refresh the list
    } catch (e) {
      debugPrint('Error creating blog post: $e');
      rethrow;
    }
  }

  Future<void> updateBlogPost(BlogPostModel post) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(post.id)
          .update(post.toFirestore());
      await loadBlogPosts(publishedOnly: false); // Refresh the list
    } catch (e) {
      debugPrint('Error updating blog post: $e');
      rethrow;
    }
  }

  Future<void> deleteBlogPost(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .delete();
      await loadBlogPosts(publishedOnly: false); // Refresh the list
    } catch (e) {
      debugPrint('Error deleting blog post: $e');
      rethrow;
    }
  }

  Future<void> publishPost(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'isPublished': true,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadBlogPosts(publishedOnly: false); // Refresh the list
    } catch (e) {
      debugPrint('Error publishing post: $e');
      rethrow;
    }
  }

  Future<void> unpublishPost(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'isPublished': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadBlogPosts(publishedOnly: false); // Refresh the list
    } catch (e) {
      debugPrint('Error unpublishing post: $e');
      rethrow;
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'recent';
    _applyFiltersAndSort();
  }
}
