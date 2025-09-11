import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/blog_post_model.dart';
import '../models/user_model.dart';

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

  // Enhanced search by title and tags
  void searchByTitleAndTags(String query) {
    _searchQuery = query.toLowerCase();
    _filteredPosts = _blogPosts.where((post) {
      return post.title.toLowerCase().contains(_searchQuery) ||
             post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    }).toList();
    notifyListeners();
  }

  // Get posts by specific author (for admin/vet management)
  Future<List<BlogPostModel>> getPostsByAuthor(String authorId, {bool includeUnpublished = false}) async {
    try {
      Query query = _firestore
          .collection('blog_posts')
          .where('authorId', isEqualTo: authorId);
      
      if (!includeUnpublished) {
        query = query.where('isPublished', isEqualTo: true);
      }
      
      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting posts by author: $e');
      return [];
    }
  }

  // Archive/Unarchive posts
  Future<void> archivePost(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadBlogPosts(publishedOnly: false);
    } catch (e) {
      debugPrint('Error archiving post: $e');
      rethrow;
    }
  }

  Future<void> unarchivePost(String postId) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'isArchived': false,
        'archivedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadBlogPosts(publishedOnly: false);
    } catch (e) {
      debugPrint('Error unarchiving post: $e');
      rethrow;
    }
  }

  // Get draft posts for authors
  Future<List<BlogPostModel>> getDraftPosts(String authorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('blog_posts')
          .where('authorId', isEqualTo: authorId)
          .where('isPublished', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting draft posts: $e');
      return [];
    }
  }

  // Get scheduled posts
  Future<List<BlogPostModel>> getScheduledPosts(String authorId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection('blog_posts')
          .where('authorId', isEqualTo: authorId)
          .where('isScheduled', isEqualTo: true)
          .where('scheduledPublishAt', isGreaterThan: now)
          .orderBy('scheduledPublishAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => BlogPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting scheduled posts: $e');
      return [];
    }
  }

  // External sharing functionality
  Future<void> sharePost(BlogPostModel post) async {
    try {
      final shareText = '${post.title}\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
      await Share.share(
        shareText,
        subject: post.title,
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared',
        'postId': post.id,
        'postTitle': post.title,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post: $e');
    }
  }

  // Share post with custom text
  Future<void> sharePostWithText(BlogPostModel post, String customText) async {
    try {
      final shareText = '$customText\n\nRead more: https://petcare.app/blog/${post.id}';
      await Share.share(
        shareText,
        subject: post.title,
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared_custom',
        'postId': post.id,
        'postTitle': post.title,
        'customText': customText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post with custom text: $e');
    }
  }

  // Get blog analytics for admin
  Future<Map<String, dynamic>> getBlogAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('blog_posts');
      
      if (startDate != null && endDate != null) {
        query = query
            .where('publishedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('publishedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final posts = querySnapshot.docs
          .map((doc) => BlogPostModel.fromFirestore(doc))
          .toList();

      // Calculate analytics
      final totalPosts = posts.length;
      final publishedPosts = posts.where((p) => p.isPublished).length;
      final totalViews = posts.fold<int>(0, (sum, p) => sum + p.viewCount);
      final totalLikes = posts.fold<int>(0, (sum, p) => sum + p.likeCount);
      final averageViews = totalPosts > 0 ? (totalViews / totalPosts).round() : 0;
      final averageLikes = totalPosts > 0 ? (totalLikes / totalPosts).round() : 0;
      
      // Category distribution
      final Map<String, int> postsByCategory = {};
      for (final post in posts) {
        final category = post.category.toString().split('.').last;
        postsByCategory[category] = (postsByCategory[category] ?? 0) + 1;
      }
      
      // Author statistics
      final Map<String, int> postsByAuthor = {};
      for (final post in posts) {
        postsByAuthor[post.authorName] = (postsByAuthor[post.authorName] ?? 0) + 1;
      }
      
      // Top performing posts
      final topPostsByViews = posts.toList()
        ..sort((a, b) => b.viewCount.compareTo(a.viewCount))
        ..take(10);
      
      final topPostsByLikes = posts.toList()
        ..sort((a, b) => b.likeCount.compareTo(a.likeCount))
        ..take(10);

      return {
        'totalPosts': totalPosts,
        'publishedPosts': publishedPosts,
        'draftPosts': totalPosts - publishedPosts,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'averageViews': averageViews,
        'averageLikes': averageLikes,
        'engagementRate': totalViews > 0 ? ((totalLikes / totalViews) * 100).round() : 0,
        'postsByCategory': postsByCategory,
        'postsByAuthor': postsByAuthor,
        'topPostsByViews': topPostsByViews.map((p) => {
          'id': p.id,
          'title': p.title,
          'views': p.viewCount,
          'author': p.authorName,
        }).toList(),
        'topPostsByLikes': topPostsByLikes.map((p) => {
          'id': p.id,
          'title': p.title,
          'likes': p.likeCount,
          'author': p.authorName,
        }).toList(),
      };
    } catch (e) {
      debugPrint('Error getting blog analytics: $e');
      return {};
    }
  }

  // Content moderation - Flag inappropriate content
  Future<void> flagPost(String postId, String reason, String reporterId) async {
    try {
      await _firestore.collection('content_reports').add({
        'type': 'blog_post',
        'contentId': postId,
        'reason': reason,
        'reporterId': reporterId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update post with flag
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        'flaggedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error flagging post: $e');
      rethrow;
    }
  }
}
