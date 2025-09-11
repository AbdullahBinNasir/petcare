import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/blog_post_model.dart';
import '../../models/user_model.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';

class BlogPostDetailsScreen extends StatefulWidget {
  final BlogPostModel post;

  const BlogPostDetailsScreen({
    super.key,
    required this.post,
  });

  @override
  State<BlogPostDetailsScreen> createState() => _BlogPostDetailsScreenState();
}

class _BlogPostDetailsScreenState extends State<BlogPostDetailsScreen> {
  bool _isLiked = false;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostData();
    });
  }

  void _loadPostData() async {
    final blogService = Provider.of<BlogService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id ?? '';

    // Increment view count
    await blogService.incrementViewCount(widget.post.id);

    if (userId.isNotEmpty) {
      // Check if post is liked and favorited
      _isLiked = await blogService.isPostLiked(widget.post.id, userId);
      _isFavorite = blogService.isPostFavorite(widget.post.id, userId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
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
            _buildHeader(),
            _buildContent(),
            _buildTags(),
            _buildAuthorInfo(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.post.featuredImageUrl != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildFeaturedImage(widget.post.featuredImageUrl!),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.excerpt,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      widget.post.authorName.isNotEmpty 
                          ? widget.post.authorName[0].toUpperCase() 
                          : 'A',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(widget.post.publishedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.readTime} min read',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            child: const Icon(Icons.image_not_supported, size: 64),
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
        child: const Icon(Icons.image_not_supported, size: 64),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Html(
        data: widget.post.content,
        style: {
          "body": Style(
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "p": Style(
            margin: Margins.only(bottom: 16),
          ),
          "h1, h2, h3, h4, h5, h6": Style(
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 24, bottom: 12),
          ),
          "img": Style(
            width: Width(double.infinity),
            margin: Margins.symmetric(vertical: 16),
          ),
          "blockquote": Style(
            border: const Border(left: BorderSide(color: Colors.grey, width: 4)),
            padding: HtmlPaddings.only(left: 16),
            margin: Margins.symmetric(vertical: 16),
            fontStyle: FontStyle.italic,
          ),
        },
      ),
    );
  }

  Widget _buildTags() {
    if (widget.post.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.post.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            child: Text(
              widget.post.authorName.isNotEmpty 
                  ? widget.post.authorName[0].toUpperCase() 
                  : 'A',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Published on ${DateFormat('MMMM dd, yyyy').format(widget.post.publishedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
              ),
            ),
            Text(
              widget.post.likeCount.toString(),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(width: 24),
            Icon(Icons.visibility, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              widget.post.viewCount.toString(),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _sharePost,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final userId = authService.currentUserModel?.id;

    if (userId == null) {
      _showSnackBar('Please log in to like posts');
      return;
    }

    try {
      await blogService.toggleLike(widget.post.id, userId);
      setState(() {
        _isLiked = !_isLiked;
      });
    } catch (e) {
      _showSnackBar('Error updating like: ${e.toString()}');
    }
  }

  void _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final userId = authService.currentUserModel?.id;

    if (userId == null) {
      _showSnackBar('Please log in to save favorites');
      return;
    }

    try {
      await blogService.toggleFavorite(widget.post.id, userId);
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar(_isFavorite ? 'Added to favorites' : 'Removed from favorites');
    } catch (e) {
      _showSnackBar('Error updating favorite: ${e.toString()}');
    }
  }

  void _sharePost() {
    Share.share(
      '${widget.post.title}\n\n${widget.post.excerpt}\n\nRead more in the Pet Care app!',
      subject: widget.post.title,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
