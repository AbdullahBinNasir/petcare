import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/blog_post_model.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';

class CreateBlogPostScreen extends StatefulWidget {
  final BlogPostModel? existingPost;

  const CreateBlogPostScreen({
    super.key,
    this.existingPost,
  });

  @override
  State<CreateBlogPostScreen> createState() => _CreateBlogPostScreenState();
}

class _CreateBlogPostScreenState extends State<CreateBlogPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _readTimeController = TextEditingController();

  BlogCategory _selectedCategory = BlogCategory.general;
  bool _isPublished = false;
  bool _isLoading = false;
  String? _featuredImageUrl;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final post = widget.existingPost!;
    _titleController.text = post.title;
    _excerptController.text = post.excerpt;
    _contentController.text = post.content;
    _tagsController.text = post.tags.join(', ');
    _readTimeController.text = post.readTime.toString();
    _selectedCategory = post.category;
    _isPublished = post.isPublished;
    _featuredImageUrl = post.featuredImageUrl;
    _imageUrls = List.from(post.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost != null ? 'Edit Post' : 'Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _savePost(false),
            child: const Text('Save Draft'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _savePost(true),
            child: const Text('Publish'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildExcerptField(),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              _buildReadTimeField(),
              const SizedBox(height: 16),
              _buildFeaturedImageSection(),
              const SizedBox(height: 16),
              _buildContentField(),
              const SizedBox(height: 16),
              _buildTagsField(),
              const SizedBox(height: 16),
              _buildImageGallerySection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Enter a compelling title for your post',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildExcerptField() {
    return TextFormField(
      controller: _excerptController,
      decoration: const InputDecoration(
        labelText: 'Excerpt',
        hintText: 'Brief summary of your post (shown in previews)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an excerpt';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<BlogCategory>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: BlogCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(_getCategoryName(category)),
        );
      }).toList(),
      onChanged: (category) {
        if (category != null) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
    );
  }

  Widget _buildReadTimeField() {
    return TextFormField(
      controller: _readTimeController,
      decoration: const InputDecoration(
        labelText: 'Estimated Read Time (minutes)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter estimated read time';
        }
        final readTime = int.tryParse(value);
        if (readTime == null || readTime <= 0) {
          return 'Please enter a valid read time';
        }
        return null;
      },
    );
  }

  Widget _buildFeaturedImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Featured Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_featuredImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _featuredImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickFeaturedImage,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Image'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _featuredImageUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _pickFeaturedImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Featured Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Content',
        hintText: 'Write your post content here. You can use HTML formatting.',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 15,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter content for your post';
        }
        return null;
      },
    );
  }

  Widget _buildTagsField() {
    return TextFormField(
      controller: _tagsController,
      decoration: const InputDecoration(
        labelText: 'Tags',
        hintText: 'Enter tags separated by commas (e.g., training, puppies, health)',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildImageGallerySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Additional Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickAdditionalImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Images'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text(
                'No additional images added',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pickFeaturedImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // In a real app, you would upload this to Firebase Storage
      // For now, we'll use a placeholder URL
      setState(() {
        _featuredImageUrl = 'https://via.placeholder.com/400x200';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image selected. In production, this would be uploaded to storage.'),
        ),
      );
    }
  }

  void _pickAdditionalImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      // In a real app, you would upload these to Firebase Storage
      // For now, we'll use placeholder URLs
      setState(() {
        for (int i = 0; i < images.length; i++) {
          _imageUrls.add('https://via.placeholder.com/200x200?text=Image${_imageUrls.length + i + 1}');
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${images.length} images selected. In production, these would be uploaded to storage.'),
        ),
      );
    }
  }

  void _savePost(bool publish) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final blogService = Provider.of<BlogService>(context, listen: false);
      final currentUser = authService.currentUserModel!;

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final now = DateTime.now();
      
      final post = BlogPostModel(
        id: widget.existingPost?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        excerpt: _excerptController.text.trim(),
        authorId: currentUser.id,
        authorName: currentUser.fullName,
        category: _selectedCategory,
        tags: tags,
        featuredImageUrl: _featuredImageUrl,
        imageUrls: _imageUrls,
        readTime: int.parse(_readTimeController.text),
        viewCount: widget.existingPost?.viewCount ?? 0,
        likeCount: widget.existingPost?.likeCount ?? 0,
        isPublished: publish,
        publishedAt: publish ? now : (widget.existingPost?.publishedAt ?? now),
        createdAt: widget.existingPost?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existingPost != null) {
        await blogService.updateBlogPost(post);
      } else {
        await blogService.createBlogPost(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Post published successfully!' : 'Post saved as draft!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
