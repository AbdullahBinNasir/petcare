import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';
import '../../models/blog_post_model.dart';
import '../../theme/pet_care_theme.dart';
import '../shared/create_blog_post_screen.dart';
import '../shared/blog_screen.dart';

class VetBlogManagementScreen extends StatefulWidget {
  const VetBlogManagementScreen({super.key});

  @override
  State<VetBlogManagementScreen> createState() => _VetBlogManagementScreenState();
}

class _VetBlogManagementScreenState extends State<VetBlogManagementScreen> {
  final BlogService _blogService = BlogService();
  List<BlogPostModel> _blogPosts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBlogPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogPosts() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final posts = await _blogService.getBlogPostsByAuthor(currentUser.uid);
        setState(() {
          _blogPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading blog posts: $e');
      setState(() => _isLoading = false);
    }
  }

  List<BlogPostModel> get _filteredPosts {
    var filtered = _blogPosts;
    
    // Filter by status
    switch (_selectedFilter) {
      case 'published':
        filtered = filtered.where((post) => post.isPublished).toList();
        break;
      case 'draft':
        filtered = filtered.where((post) => !post.isPublished).toList();
        break;
      case 'archived':
        filtered = filtered.where((post) => post.isArchived).toList();
        break;
    }
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((post) =>
        post.title.toLowerCase().contains(query) ||
        post.excerpt.toLowerCase().contains(query) ||
        post.content.toLowerCase().contains(query)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: PetCareTheme.primaryGradient,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: PetCareTheme.primaryBeige,
        title: const Text(
          'My Blog Posts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: PetCareTheme.primaryBeige,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBlogPosts,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.visibility_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlogScreen(),
                ),
              );
            },
            tooltip: 'View Public Blog',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search blog posts...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: PetCareTheme.lightBrown.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: PetCareTheme.lightBrown.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: PetCareTheme.primaryBrown,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: PetCareTheme.cardWhite,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Published', 'published'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Drafts', 'draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Archived', 'archived'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Blog Posts List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBrown),
                    ),
                  )
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: PetCareTheme.lightBrown.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No posts found matching your search'
                                  : 'No blog posts yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: PetCareTheme.lightBrown.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try adjusting your search terms'
                                  : 'Create your first blog post to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: PetCareTheme.lightBrown.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return _buildBlogPostCard(post);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBlogPostScreen(),
            ),
          );
          if (result == true) {
            _loadBlogPosts();
          }
        },
        backgroundColor: PetCareTheme.primaryBrown,
        foregroundColor: PetCareTheme.primaryBeige,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: PetCareTheme.primaryBrown.withOpacity(0.2),
      checkmarkColor: PetCareTheme.primaryBrown,
      labelStyle: TextStyle(
        color: isSelected ? PetCareTheme.primaryBrown : PetCareTheme.lightBrown,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: PetCareTheme.cardWhite,
      side: BorderSide(
        color: isSelected ? PetCareTheme.primaryBrown : PetCareTheme.lightBrown.withOpacity(0.3),
      ),
    );
  }

  Widget _buildBlogPostCard(BlogPostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PetCareTheme.lightBrown.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBlogPostScreen(existingPost: post),
            ),
          );
            if (result == true) {
              _loadBlogPosts();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and actions
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(post).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(post).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(post),
                        style: TextStyle(
                          color: _getStatusColor(post),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Actions
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, post),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: post.isPublished ? 'unpublish' : 'publish',
                          child: Row(
                            children: [
                              Icon(
                                post.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(post.isPublished ? 'Unpublish' : 'Publish'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: post.isArchived ? 'unarchive' : 'archive',
                          child: Row(
                            children: [
                              Icon(
                                post.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(post.isArchived ? 'Unarchive' : 'Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: PetCareTheme.lightBrown.withOpacity(0.7),
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
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBrown,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Excerpt
                Text(
                  post.excerpt,
                  style: TextStyle(
                    fontSize: 14,
                    color: PetCareTheme.lightBrown.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer with stats and date
                Row(
                  children: [
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: PetCareTheme.lightBrown.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: PetCareTheme.lightBrown.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: PetCareTheme.lightBrown.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: PetCareTheme.lightBrown.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Date
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: PetCareTheme.lightBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BlogPostModel post) {
    if (post.isArchived) return Colors.grey;
    if (post.isPublished) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText(BlogPostModel post) {
    if (post.isArchived) return 'Archived';
    if (post.isPublished) return 'Published';
    return 'Draft';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleMenuAction(String action, BlogPostModel post) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateBlogPostScreen(existingPost: post),
          ),
        );
        if (result == true) {
          _loadBlogPosts();
        }
        break;
      case 'publish':
        await _blogService.updateBlogPostFields(post.id, {'isPublished': true});
        _loadBlogPosts();
        break;
      case 'unpublish':
        await _blogService.updateBlogPostFields(post.id, {'isPublished': false});
        _loadBlogPosts();
        break;
      case 'archive':
        await _blogService.updateBlogPostFields(post.id, {'isArchived': true});
        _loadBlogPosts();
        break;
      case 'unarchive':
        await _blogService.updateBlogPostFields(post.id, {'isArchived': false});
        _loadBlogPosts();
        break;
      case 'delete':
        await _showDeleteDialog(post);
        break;
    }
  }

  Future<void> _showDeleteDialog(BlogPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog Post'),
        content: Text('Are you sure you want to delete "${post.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _blogService.deleteBlogPost(post.id);
      _loadBlogPosts();
    }
  }
}
