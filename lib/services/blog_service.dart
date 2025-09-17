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
    debugPrint('DEBUG: Loading blog posts - publishedOnly: $publishedOnly');
    _isLoading = true;
    notifyListeners();

    try {
      // First, let's get ALL blog posts to see what's in the database
      final allPostsQuery = await _firestore.collection('blog_posts').get();
      debugPrint('DEBUG: Total posts in database: ${allPostsQuery.docs.length}');
      
      for (var doc in allPostsQuery.docs) {
        final data = doc.data();
        debugPrint('DEBUG: Raw post data - ID: ${doc.id}, Title: ${data['title']}, isPublished: ${data['isPublished']}, publishedAt: ${data['publishedAt']}');
      }

      Query query = _firestore.collection('blog_posts');
      
      if (publishedOnly) {
        query = query.where('isPublished', isEqualTo: true);
        debugPrint('DEBUG: Filtering for published posts only');
      }
      
      // Try to get documents without ordering first to see if that's the issue
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await query
            .orderBy('publishedAt', descending: true)
            .get();
        debugPrint('DEBUG: Query with orderBy successful');
      } catch (orderError) {
        debugPrint('DEBUG: OrderBy failed, trying without orderBy: $orderError');
        // If ordering fails, try without it
        querySnapshot = await query.get();
        debugPrint('DEBUG: Query without orderBy successful');
      }

      debugPrint('DEBUG: Found ${querySnapshot.docs.length} documents in Firestore after filtering');

      _blogPosts = querySnapshot.docs
          .map((doc) {
            try {
              return BlogPostModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('DEBUG: Error parsing document ${doc.id}: $e');
              debugPrint('DEBUG: Document data: ${doc.data()}');
              return null;
            }
          })
          .where((post) => post != null)
          .cast<BlogPostModel>()
          .toList();

      debugPrint('DEBUG: Parsed ${_blogPosts.length} blog posts');
      for (var post in _blogPosts) {
        debugPrint('DEBUG: Post - Title: ${post.title}, Published: ${post.isPublished}, PublishedAt: ${post.publishedAt}');
      }

      // Sort manually if we couldn't use orderBy
      _blogPosts.sort((a, b) {
        try {
          return b.publishedAt.compareTo(a.publishedAt);
        } catch (e) {
          debugPrint('DEBUG: Error comparing publishedAt dates: $e');
          // Fallback to createdAt if publishedAt comparison fails
          return b.createdAt.compareTo(a.createdAt);
        }
      });

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
    debugPrint('DEBUG: _applyFiltersAndSort - Starting with ${_blogPosts.length} posts');
    _filteredPosts = List.from(_blogPosts);
    debugPrint('DEBUG: _applyFiltersAndSort - After copying: ${_filteredPosts.length} posts');

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      debugPrint('DEBUG: _applyFiltersAndSort - Applying search filter: "$_searchQuery"');
      _filteredPosts = _filteredPosts.where((post) {
        return post.title.toLowerCase().contains(_searchQuery) ||
               post.excerpt.toLowerCase().contains(_searchQuery) ||
               post.content.toLowerCase().contains(_searchQuery) ||
               post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
      debugPrint('DEBUG: _applyFiltersAndSort - After search filter: ${_filteredPosts.length} posts');
    }

    // Apply category filter
    if (_selectedCategory != null) {
      debugPrint('DEBUG: _applyFiltersAndSort - Applying category filter: $_selectedCategory');
      _filteredPosts = _filteredPosts
          .where((post) => post.category == _selectedCategory)
          .toList();
      debugPrint('DEBUG: _applyFiltersAndSort - After category filter: ${_filteredPosts.length} posts');
    }

    // Apply sorting
    debugPrint('DEBUG: _applyFiltersAndSort - Applying sort: $_sortBy');
    switch (_sortBy) {
      case 'recent':
        _filteredPosts.sort((a, b) {
          try {
            return b.publishedAt.compareTo(a.publishedAt);
          } catch (e) {
            debugPrint('DEBUG: Error in recent sort: $e');
            return b.createdAt.compareTo(a.createdAt);
          }
        });
        break;
      case 'popular':
        _filteredPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'oldest':
        _filteredPosts.sort((a, b) {
          try {
            return a.publishedAt.compareTo(b.publishedAt);
          } catch (e) {
            debugPrint('DEBUG: Error in oldest sort: $e');
            return a.createdAt.compareTo(b.createdAt);
          }
        });
        break;
      case 'likes':
        _filteredPosts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
    }

    debugPrint('DEBUG: _applyFiltersAndSort - Final filtered posts: ${_filteredPosts.length}');
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
      if (post.id.isEmpty) {
        // Generate a new document ID
        final docRef = await _firestore.collection('blog_posts').add(post.toFirestore());
        debugPrint('Created blog post with ID: ${docRef.id}');
      } else {
        // Use the provided ID
        await _firestore.collection('blog_posts').doc(post.id).set(post.toFirestore());
        debugPrint('Created blog post with provided ID: ${post.id}');
      }
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

  // Update specific fields of a blog post
  Future<void> updateBlogPostFields(String postId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('blog_posts')
          .doc(postId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating blog post fields: $e');
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

  // Alias for getPostsByAuthor for consistency
  Future<List<BlogPostModel>> getBlogPostsByAuthor(String authorId) async {
    return getPostsByAuthor(authorId, includeUnpublished: true);
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
        'category': post.categoryName,
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
        'category': post.categoryName,
        'customText': customText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post with custom text: $e');
    }
  }

  // Share post to specific platforms
  Future<void> sharePostToPlatform(BlogPostModel post, String platform) async {
    try {
      String shareText = '';
      String subject = '';
      
      switch (platform.toLowerCase()) {
        case 'whatsapp':
          shareText = '*${post.title}*\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
          subject = post.title;
          break;
        case 'facebook':
          shareText = '${post.title}\n\n${post.excerpt}\n\nRead the full article: https://petcare.app/blog/${post.id}';
          subject = post.title;
          break;
        case 'twitter':
          shareText = '${post.title}\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
          subject = post.title;
          break;
        case 'instagram':
          shareText = '${post.title}\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
          subject = post.title;
          break;
        default:
          shareText = '${post.title}\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
          subject = post.title;
      }
      
      await Share.share(
        shareText,
        subject: subject,
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared_platform',
        'postId': post.id,
        'postTitle': post.title,
        'category': post.categoryName,
        'platform': platform,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post to $platform: $e');
    }
  }

  // Share post as image (for social media)
  Future<void> sharePostAsImage(BlogPostModel post) async {
    try {
      final shareText = '${post.title}\n\n${post.excerpt}\n\nRead more: https://petcare.app/blog/${post.id}';
      
      await Share.share(
        shareText,
        subject: post.title,
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared_image',
        'postId': post.id,
        'postTitle': post.title,
        'category': post.categoryName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post as image: $e');
    }
  }

  // Elaborate sharing for blog post details screen
  Future<void> sharePostDetailed(BlogPostModel post) async {
    try {
      final shareText = '''
🐾 ${post.title}

${post.excerpt}

📚 Category: ${post.categoryName}
👤 Author: ${post.authorName}
⏱️ Read Time: ${post.readTime} minutes
👁️ Views: ${post.viewCount}
❤️ Likes: ${post.likeCount}

${post.tags.isNotEmpty ? '🏷️ Tags: ${post.tags.join(', ')}' : ''}

📖 Read the complete article:
https://petcare.app/blog/${post.id}

---
🐕 Pet Care App - Your trusted companion for pet health and wellness
#PetCare #PetTips #${post.categoryName} #PetHealth #PetLovers
      ''';
      
      await Share.share(
        shareText,
        subject: '🐾 ${post.title} - Pet Care Tips',
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared_detailed',
        'postId': post.id,
        'postTitle': post.title,
        'category': post.categoryName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post detailed: $e');
    }
  }

  // Platform-specific detailed sharing
  Future<void> sharePostDetailedToPlatform(BlogPostModel post, String platform) async {
    try {
      String shareText = '';
      String subject = '';
      
      switch (platform.toLowerCase()) {
        case 'whatsapp':
          shareText = '''
🐾 *${post.title}*

${post.excerpt}

📚 *Category:* ${post.categoryName}
👤 *Author:* ${post.authorName}
⏱️ *Read Time:* ${post.readTime} minutes

${post.tags.isNotEmpty ? '🏷️ *Tags:* ${post.tags.join(', ')}' : ''}

📖 *Read the complete article:*
https://petcare.app/blog/${post.id}

---
🐕 *Pet Care App* - Your trusted companion for pet health and wellness
#PetCare #PetTips #${post.categoryName} #PetHealth #PetLovers
          ''';
          subject = '🐾 ${post.title} - Pet Care Tips';
          break;
        case 'facebook':
          shareText = '''
🐾 ${post.title}

${post.excerpt}

📚 Category: ${post.categoryName}
👤 Author: ${post.authorName}
⏱️ Read Time: ${post.readTime} minutes
👁️ Views: ${post.viewCount}

${post.tags.isNotEmpty ? '🏷️ Tags: ${post.tags.join(', ')}' : ''}

📖 Read the complete article here:
https://petcare.app/blog/${post.id}

---
🐕 Pet Care App - Your trusted companion for pet health and wellness
#PetCare #PetTips #${post.categoryName} #PetHealth #PetLovers
          ''';
          subject = '🐾 ${post.title} - Pet Care Tips';
          break;
        case 'twitter':
          // Twitter has character limit, so we need to be concise
          final shortExcerpt = post.excerpt.length > 100 ? '${post.excerpt.substring(0, 100)}...' : post.excerpt;
          shareText = '''
🐾 ${post.title}

${shortExcerpt}

📚 ${post.categoryName} | 👤 ${post.authorName} | ⏱️ ${post.readTime}min

📖 Read more: https://petcare.app/blog/${post.id}

#PetCare #PetTips #${post.categoryName} #PetHealth
          ''';
          subject = 'Pet Care Tips';
          break;
        case 'instagram':
          shareText = '''
🐾 ${post.title}

${post.excerpt}

📚 ${post.categoryName} | 👤 ${post.authorName} | ⏱️ ${post.readTime}min

${post.tags.isNotEmpty ? '🏷️ ${post.tags.join(' ')}' : ''}

📖 Read more: https://petcare.app/blog/${post.id}

#PetCare #PetTips #${post.categoryName} #PetHealth #PetLovers #PetWellness #PetCareApp
          ''';
          subject = '🐾 ${post.title} - Pet Care Tips';
          break;
        default:
          shareText = '''
🐾 ${post.title}

${post.excerpt}

📚 Category: ${post.categoryName}
👤 Author: ${post.authorName}
⏱️ Read Time: ${post.readTime} minutes

📖 Read more: https://petcare.app/blog/${post.id}

#PetCare #PetTips #${post.categoryName}
          ''';
          subject = 'Pet Care Tips';
      }
      
      await Share.share(
        shareText,
        subject: subject,
      );
      
      // Track sharing analytics
      await _firestore.collection('analytics').add({
        'eventType': 'blog_post_shared_detailed_platform',
        'postId': post.id,
        'postTitle': post.title,
        'category': post.categoryName,
        'platform': platform,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sharing post detailed to $platform: $e');
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
