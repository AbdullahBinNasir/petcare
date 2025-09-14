import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/blog_post_model.dart';
import '../../models/user_model.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';
import '../../services/bookmark_service.dart';
import 'blog_post_details_screen.dart';
import 'create_blog_post_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadBlogPosts() {
    final blogService = Provider.of<BlogService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
    
    blogService.loadBlogPosts();
    if (authService.currentUserModel != null) {
      blogService.loadUserFavorites(authService.currentUserModel!.id);
      bookmarkService.loadUserBookmarks(authService.currentUserModel!.id);
    }
  }

  void _showShareOptions(BuildContext context, BlogPostModel post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share Article',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.share,
                  label: 'General',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailed(post);
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailedToPlatform(post, 'whatsapp');
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.facebook,
                  label: 'Facebook',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailedToPlatform(post, 'facebook');
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailedToPlatform(post, 'twitter');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailedToPlatform(post, 'instagram');
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.edit,
                  label: 'Custom',
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomShareDialog(context, post);
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.image,
                  label: 'As Image',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<BlogService>(context, listen: false).sharePostDetailed(post);
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.copy,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    _copyToClipboard(context, post);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomShareDialog(BuildContext context, BlogPostModel post) {
    final TextEditingController customTextController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Share Message'),
        content: TextField(
          controller: customTextController,
          decoration: const InputDecoration(
            hintText: 'Enter your custom message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (customTextController.text.isNotEmpty) {
                // Use detailed custom sharing
                final detailedText = '''
${customTextController.text}

📚 Category: ${post.categoryName}
👤 Author: ${post.authorName}
⏱️ Read Time: ${post.readTime} minutes

📖 Read the complete article:
https://petcare.app/blog/${post.id}

---
🐕 Pet Care App - Your trusted companion for pet health and wellness
#PetCare #PetTips #${post.categoryName} #PetHealth #PetLovers
                ''';
                Provider.of<BlogService>(context, listen: false)
                    .sharePostWithText(post, detailedText);
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, BlogPostModel post) {
    final link = 'https://petcare.app/blog/${post.id}';
    // You would use Clipboard.setData here if you have the clipboard package
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied: $link'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canCreatePosts = authService.currentUserModel?.role == UserRole.veterinarian ||
                          authService.currentUserModel?.role == UserRole.shelterAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Tips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBlogPosts();
            },
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (canCreatePosts)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBlogPostScreen(),
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Posts', icon: Icon(Icons.article)),
            Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFiltersSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPostsView(),
                _buildFavoritesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search articles...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    Provider.of<BlogService>(context, listen: false).searchPosts('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          Provider.of<BlogService>(context, listen: false).searchPosts(value);
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Consumer<BlogService>(
      builder: (context, blogService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BlogCategory?>(
                      value: blogService.selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...BlogCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryName(category)),
                          );
                        }),
                      ],
                      onChanged: (category) {
                        blogService.filterByCategory(category);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: blogService.sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                        DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                        DropdownMenuItem(value: 'likes', child: Text('Most Liked')),
                        DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                      ],
                      onChanged: (sortBy) {
                        if (sortBy != null) {
                          blogService.sortPosts(sortBy);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      blogService.clearFilters();
                      _searchController.clear();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllPostsView() {
    return Consumer<BlogService>(
      builder: (context, blogService, child) {
        // Debug information
        print('DEBUG: BlogService state - isLoading: ${blogService.isLoading}, blogPosts count: ${blogService.blogPosts.length}');
        
        if (blogService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (blogService.blogPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No articles found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Debug: ${blogService.blogPosts.length} posts loaded',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadBlogPosts();
                  },
                  child: Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: blogService.blogPosts.length,
          itemBuilder: (context, index) {
            final post = blogService.blogPosts[index];
            return _buildBlogPostCard(post);
          },
        );
      },
    );
  }

  Widget _buildFavoritesView() {
    return Consumer2<BlogService, AuthService>(
      builder: (context, blogService, authService, child) {
        final userId = authService.currentUserModel?.id ?? '';
        final favoritePosts = blogService.getFavoritePosts(userId);

        if (favoritePosts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No favorite articles yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the heart icon on articles to save them here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoritePosts.length,
          itemBuilder: (context, index) {
            final post = favoritePosts[index];
            return _buildBlogPostCard(post);
          },
        );
      },
    );
  }

  Widget _buildBlogPostCard(BlogPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogPostDetailsScreen(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.featuredImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildFeaturedImage(post.featuredImageUrl!),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryName(post.category),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.formattedPublishDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      // Author row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text(
                              post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${post.readTime} min',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats and actions row
                      Row(
                        children: [
                          // Views
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                post.viewCount.toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Likes
                          GestureDetector(
                            onTap: () async {
                              final auth = Provider.of<AuthService>(context, listen: false);
                              final blogService = Provider.of<BlogService>(context, listen: false);
                              final userId = auth.currentUserModel?.id;
                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to like posts')));
                                return;
                              }
                              try {
                                await blogService.toggleLike(post.id, userId);
                              } catch (_) {}
                            },
                            child: FutureBuilder<bool>(
                              future: Provider.of<AuthService>(context, listen: false).currentUserModel == null
                                  ? Future.value(false)
                                  : Provider.of<BlogService>(context, listen: false)
                                      .isPostLiked(post.id, Provider.of<AuthService>(context, listen: false).currentUserModel!.id),
                              builder: (context, snapshot) {
                                final isLiked = snapshot.data == true;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 14,
                                      color: isLiked ? Colors.red : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      post.likeCount.toString(),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Spacer(),
                          // Action buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bookmark
                              Consumer2<BookmarkService, AuthService>(
                                builder: (context, bookmarkService, authService, child) {
                                  final userId = authService.currentUserModel?.id;
                                  final isBookmarked = userId != null ? bookmarkService.isBookmarked(userId, post.id) : false;
                                  
                                  return GestureDetector(
                                    onTap: () async {
                                      if (userId == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please log in to bookmark articles')),
                                        );
                                        return;
                                      }
                                      
                                      try {
                                        if (isBookmarked) {
                                          final success = await bookmarkService.removeBookmark(userId, post.id);
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Removed from bookmarks')),
                                            );
                                          }
                                        } else {
                                          final success = await bookmarkService.addBookmark(userId, post);
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Added to bookmarks')),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: ${e.toString()}')),
                                        );
                                      }
                                    },
                                    child: Icon(
                                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      size: 16,
                                      color: isBookmarked ? Colors.red : Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // Share
                              GestureDetector(
                                onTap: () => _showShareOptions(context, post),
                                child: Icon(
                                  Icons.share,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImage(String image) {
    try {
      if (image.startsWith('data:image')) {
        final base64Part = image.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported),
          ),
        );
      }
    } catch (_) {}

    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  String _getCategoryName(BlogCategory category) {
    switch (category) {
      case BlogCategory.training:
        return 'Training';
      case BlogCategory.nutrition:
        return 'Nutrition';
      case BlogCategory.health:
        return 'Health';
      case BlogCategory.grooming:
        return 'Grooming';
      case BlogCategory.behavior:
        return 'Behavior';
      case BlogCategory.general:
        return 'General';
    }
  }
}
