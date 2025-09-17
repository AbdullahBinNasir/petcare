import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/blog_post_model.dart';
import '../../services/blog_service.dart';
import '../../utils/blog_image_helper.dart';
import 'create_blog_post_screen.dart';

class AdminBlogManagementScreen extends StatefulWidget {
  const AdminBlogManagementScreen({super.key});

  @override
  State<AdminBlogManagementScreen> createState() => _AdminBlogManagementScreenState();
}

class _AdminBlogManagementScreenState extends State<AdminBlogManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogService>(context, listen: false).loadBlogPosts(publishedOnly: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fixAllBlogImages() async {
    try {
      await BlogImageHelper.addImagesToAllBlogPosts();
      
      // Reload the blog posts to show the new images
      Provider.of<BlogService>(context, listen: false).loadBlogPosts(publishedOnly: false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fixed images for all blog posts'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error fixing blog images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Management'),
        actions: [
          // Debug button for fixing images
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            onPressed: _fixAllBlogImages,
            tooltip: 'Fix Blog Images',
          ),
          // Add new post button
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
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCards(),
          Expanded(child: _buildPostsList()),
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
          hintText: 'Search blog posts...',
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

  Widget _buildStatsCards() {
    return Consumer<BlogService>(
      builder: (context, blogService, child) {
        final totalPosts = blogService.blogPosts.length;
        final publishedPosts = blogService.blogPosts.where((post) => post.isPublished).length;
        final draftPosts = totalPosts - publishedPosts;
        final totalViews = blogService.blogPosts.fold<int>(0, (sum, post) => sum + post.viewCount);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Posts',
                  totalPosts.toString(),
                  Icons.article,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Published',
                  publishedPosts.toString(),
                  Icons.publish,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Drafts',
                  draftPosts.toString(),
                  Icons.drafts,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  totalViews.toString(),
                  Icons.visibility,
                  Colors.purple,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return Consumer<BlogService>(
      builder: (context, blogService, child) {
        if (blogService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (blogService.blogPosts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No blog posts found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
            return _buildPostCard(post);
          },
        );
      },
    );
  }

  Widget _buildPostCard(BlogPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (post.featuredImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: post.featuredImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, size: 32),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: post.isPublished ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.isPublished ? 'Published' : 'Draft',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.categoryName,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${post.authorName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.publishedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.viewCount.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.likeCount.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, post),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
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
                        post.isPublished ? Icons.unpublished : Icons.publish,
                        color: post.isPublished ? Colors.orange : Colors.green,
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
                      Icon(post.isArchived ? Icons.unarchive : Icons.archive, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text(post.isArchived ? 'Unarchive' : 'Archive'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, BlogPostModel post) async {
    final blogService = Provider.of<BlogService>(context, listen: false);

    try {
      switch (action) {
        case 'edit':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBlogPostScreen(existingPost: post),
            ),
          );
          break;
        case 'publish':
          await blogService.publishPost(post.id);
          _showSnackBar('Post published successfully');
          break;
        case 'unpublish':
          await blogService.unpublishPost(post.id);
          _showSnackBar('Post unpublished successfully');
          break;
        case 'archive':
          await blogService.archivePost(post.id);
          _showSnackBar('Post archived');
          break;
        case 'unarchive':
          await blogService.unarchivePost(post.id);
          _showSnackBar('Post unarchived');
          break;
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String postTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "$postTitle"?'),
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
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
