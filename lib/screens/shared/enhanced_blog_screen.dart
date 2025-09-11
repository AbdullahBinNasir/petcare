import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../models/blog_post_model.dart';
import '../../models/user_model.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';

class EnhancedBlogScreen extends StatefulWidget {
  const EnhancedBlogScreen({super.key});

  @override
  State<EnhancedBlogScreen> createState() => _EnhancedBlogScreenState();
}

class _EnhancedBlogScreenState extends State<EnhancedBlogScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  BlogCategory? _selectedCategory;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blogService = Provider.of<BlogService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      blogService.loadBlogPosts();
      if (authService.currentUserModel != null) {
        blogService.loadUserFavorites(authService.currentUserModel!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    final isAuthor = user?.role == UserRole.veterinarian || user?.role == UserRole.shelterAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Blog'),
        bottom: isAuthor ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.public), text: 'Published'),
            Tab(icon: Icon(Icons.drafts), text: 'Drafts'),
            Tab(icon: Icon(Icons.schedule), text: 'Scheduled'),
          ],
        ) : null,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => _handleFilterSelection(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Posts')),
              const PopupMenuItem(value: 'training', child: Text('Training')),
              const PopupMenuItem(value: 'nutrition', child: Text('Nutrition')),
              const PopupMenuItem(value: 'health', child: Text('Health')),
              const PopupMenuItem(value: 'grooming', child: Text('Grooming')),
              const PopupMenuItem(value: 'behavior', child: Text('Behavior')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'favorites', child: Text('My Favorites')),
            ],
          ),
          // Author tools
          if (isAuthor)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleAuthorAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'create', child: Text('New Post')),
                const PopupMenuItem(value: 'analytics', child: Text('Analytics')),
                const PopupMenuItem(value: 'manage', child: Text('Manage Posts')),
              ],
            ),
        ],
      ),
      body: isAuthor ? TabBarView(
        controller: _tabController,
        children: [
          _buildBlogList(publishedOnly: true),
          _buildDraftsList(),
          _buildScheduledList(),
        ],
      ) : _buildBlogList(),
    );
  }

  Widget _buildBlogList({bool publishedOnly = true}) {
    return Consumer<BlogService>(
      builder: (context, blogService, child) {
        if (blogService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<BlogPostModel> posts = _showOnlyFavorites 
            ? blogService.getFavoritePosts(Provider.of<AuthService>(context, listen: false).currentUserModel?.id ?? '')
            : blogService.blogPosts;

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _showOnlyFavorites 
                      ? 'No favorite posts yet'
                      : 'No blog posts found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(post, blogService);
          },
        );
      },
    );
  }

  Widget _buildDraftsList() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<BlogPostModel>>(
      future: Provider.of<BlogService>(context, listen: false).getDraftPosts(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final drafts = snapshot.data ?? [];
        if (drafts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No draft posts'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final post = drafts[index];
            return _buildDraftCard(post);
          },
        );
      },
    );
  }

  Widget _buildScheduledList() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<BlogPostModel>>(
      future: Provider.of<BlogService>(context, listen: false).getScheduledPosts(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final scheduled = snapshot.data ?? [];
        if (scheduled.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No scheduled posts'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scheduled.length,
          itemBuilder: (context, index) {
            final post = scheduled[index];
            return _buildScheduledCard(post);
          },
        );
      },
    );
  }

  Widget _buildPostCard(BlogPostModel post, BlogService blogService) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUserModel;
    final isFavorite = currentUser != null
        ? blogService.isPostFavorite(post.id, currentUser.id)
        : false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Image
          if (post.featuredImageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: post.featuredImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          
          // Post Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Author
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.categoryName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'by ${post.authorName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
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
                
                // Excerpt
                Text(
                  post.excerpt,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Tags
                if (post.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: post.tags.take(3).map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                const SizedBox(height: 12),
                
                // Stats and Actions
                Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                    Text(' ${post.viewCount}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 16, color: Colors.grey.shade600),
                    Text(' ${post.likeCount}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    Text(' ${post.readTime}min', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    
                    // Action buttons
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        color: isFavorite ? Theme.of(context).primaryColor : Colors.grey,
                        size: 20,
                      ),
                      onPressed: currentUser != null
                          ? () => blogService.toggleFavorite(post.id, currentUser.id)
                          : null,
                      tooltip: 'Save to favorites',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () => blogService.sharePost(post),
                      tooltip: 'Share post',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(BlogPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.drafts, color: Colors.white, size: 20),
        ),
        title: Text(post.title),
        subtitle: Text('Last updated: ${post.formattedPublishDate}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleDraftAction(action, post),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'publish', child: Text('Publish')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _openPostDetails(post),
      ),
    );
  }

  Widget _buildScheduledCard(BlogPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.schedule, color: Colors.white, size: 20),
        ),
        title: Text(post.title),
        subtitle: Text('Scheduled for: ${post.scheduledPublishAt != null ? post.scheduledPublishAt.toString().split('.')[0] : 'Not set'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleScheduledAction(action, post),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'publish_now', child: Text('Publish Now')),
            const PopupMenuItem(value: 'cancel', child: Text('Cancel Schedule')),
          ],
        ),
        onTap: () => _openPostDetails(post),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Posts'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title or tags...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Provider.of<BlogService>(context, listen: false).searchPosts('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<BlogService>(context, listen: false)
                  .searchByTitleAndTags(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _handleFilterSelection(String value) {
    final blogService = Provider.of<BlogService>(context, listen: false);
    
    setState(() {
      _showOnlyFavorites = value == 'favorites';
    });

    if (value == 'all') {
      blogService.filterByCategory(null);
    } else if (value != 'favorites') {
      final category = BlogCategory.values.firstWhere(
        (c) => c.toString().split('.').last == value,
        orElse: () => BlogCategory.general,
      );
      blogService.filterByCategory(category);
    }
  }

  void _handleAuthorAction(String action) {
    switch (action) {
      case 'create':
        _showCreatePostDialog();
        break;
      case 'analytics':
        _showAnalytics();
        break;
      case 'manage':
        _showManagePosts();
        break;
    }
  }

  void _handleDraftAction(String action, BlogPostModel post) async {
    final blogService = Provider.of<BlogService>(context, listen: false);
    
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'publish':
        try {
          await blogService.publishPost(post.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post published successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error publishing post: $e')),
            );
          }
        }
        break;
      case 'delete':
        _confirmDelete(post);
        break;
    }
  }

  void _handleScheduledAction(String action, BlogPostModel post) async {
    final blogService = Provider.of<BlogService>(context, listen: false);
    
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'publish_now':
        try {
          await blogService.publishPost(post.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post published successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error publishing post: $e')),
            );
          }
        }
        break;
      case 'cancel':
        // Cancel scheduling logic
        break;
    }
  }

  void _openPostDetails(BlogPostModel post) {
    final blogService = Provider.of<BlogService>(context, listen: false);
    blogService.incrementViewCount(post.id);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogPostDetailsScreen(post: post),
      ),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Create New Post'),
        content: Text('This will navigate to the post creation screen.'),
      ),
    );
  }

  void _showAnalytics() async {
    final blogService = Provider.of<BlogService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics...'),
          ],
        ),
      ),
    );

    try {
      final analytics = await blogService.getBlogAnalytics();
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Blog Analytics'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnalyticRow('Total Posts', '${analytics['totalPosts'] ?? 0}'),
                _buildAnalyticRow('Published', '${analytics['publishedPosts'] ?? 0}'),
                _buildAnalyticRow('Total Views', '${analytics['totalViews'] ?? 0}'),
                _buildAnalyticRow('Total Likes', '${analytics['totalLikes'] ?? 0}'),
                _buildAnalyticRow('Engagement Rate', '${analytics['engagementRate'] ?? 0}%'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  void _showManagePosts() {
    // Navigate to post management screen
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Manage Posts'),
        content: Text('This will navigate to the post management screen.'),
      ),
    );
  }

  void _confirmDelete(BlogPostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<BlogService>(context, listen: false)
                    .deleteBlogPost(post.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting post: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

// Blog Post Details Screen
class BlogPostDetailsScreen extends StatefulWidget {
  final BlogPostModel post;

  const BlogPostDetailsScreen({super.key, required this.post});

  @override
  State<BlogPostDetailsScreen> createState() => _BlogPostDetailsScreenState();
}

class _BlogPostDetailsScreenState extends State<BlogPostDetailsScreen> {
  bool isLiked = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadUserActions();
  }

  void _loadUserActions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user != null) {
      final liked = await blogService.isPostLiked(widget.post.id, user.id);
      final favorite = blogService.isPostFavorite(widget.post.id, user.id);
      setState(() {
        isLiked = liked;
        isFavorite = favorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: isFavorite ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image
            if (widget.post.featuredImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: widget.post.featuredImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.post.categoryName,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Author and meta
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          widget.post.authorName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${widget.post.formattedPublishDate} • ${widget.post.readTime}min read',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Content
                  Html(
                    data: widget.post.content,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                      ),
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Tags
                  if (widget.post.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.post.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      )).toList(),
                    ),
                  const SizedBox(height: 32),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: '${widget.post.likeCount}',
                        onPressed: _toggleLike,
                        color: isLiked ? Colors.red : null,
                      ),
                      _buildActionButton(
                        icon: Icons.visibility,
                        label: '${widget.post.viewCount}',
                        onPressed: null,
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: _sharePost,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  void _toggleLike() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user != null) {
      await blogService.toggleLike(widget.post.id, user.id);
      setState(() => isLiked = !isLiked);
    }
  }

  void _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user != null) {
      await blogService.toggleFavorite(widget.post.id, user.id);
      setState(() => isFavorite = !isFavorite);
    }
  }

  void _sharePost() {
    final blogService = Provider.of<BlogService>(context, listen: false);
    blogService.sharePost(widget.post);
  }
}
