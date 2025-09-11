import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
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
  File? _featuredImageFile; // for upload
  List<File> _galleryImageFiles = []; // for upload
  Uint8List? _featuredImageBytes; // web preview/upload
  List<Uint8List> _galleryImageBytes = []; // web preview/upload

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _populateFields();
    }
    // Provide sensible defaults
    if (_readTimeController.text.trim().isEmpty) {
      _readTimeController.text = '3';
    }
  }

  String _sanitizeStorageId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return DateTime.now().millisecondsSinceEpoch.toString();
    final sanitized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9_\-]"), '_')
        .replaceAll(RegExp(r"_+"), '_');
    return sanitized;
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
            if (_featuredImageBytes != null || _featuredImageFile != null || _featuredImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildFeaturedPreview(),
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
                        _featuredImageFile = null;
                        _featuredImageBytes = null;
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
            if (_galleryImageBytes.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryImageBytes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _galleryImageBytes[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _galleryImageBytes.removeAt(index);
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
              const SizedBox(height: 8),
            ],
            if (_galleryImageFiles.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryImageFiles.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _galleryImageFiles[index],
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
                                  _galleryImageFiles.removeAt(index);
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
              const SizedBox(height: 8),
            ],
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
                            child: _buildPreviewImage(_imageUrls[index]),
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

  Widget _buildPreviewImage(String image) {
    try {
      if (image.startsWith('data:image')) {
        final base64Part = image.split(',').last;
        final bytes = base64Part.isNotEmpty ? base64Decode(base64Part) : null;
        if (bytes != null) {
          return Image.memory(
            bytes,
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
          );
        }
      }
    } catch (_) {}

    return Image.network(
      image,
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
    );
  }

  Widget _buildFeaturedPreview() {
    if (_featuredImageBytes != null) {
      return Image.memory(
        _featuredImageBytes!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (_featuredImageFile != null && !kIsWeb) {
      return Image.file(
        _featuredImageFile!,
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
      );
    }

    if (_featuredImageUrl != null) {
      final image = _featuredImageUrl!;
      try {
        if (image.startsWith('data:image')) {
          final base64Part = image.split(',').last;
          final bytes = base64Part.isNotEmpty ? base64Decode(base64Part) : null;
          if (bytes != null) {
            return Image.memory(
              bytes,
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
            );
          }
        }
      } catch (_) {}

      return Image.network(
        image,
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
      );
    }

    return const SizedBox.shrink();
  }

  void _pickFeaturedImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = kIsWeb ? await image.readAsBytes() : await File(image.path).readAsBytes();
      final lower = image.name.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final base64Str = base64Encode(bytes);
      final dataUrl = 'data:$mime;base64,$base64Str';
      setState(() {
        _featuredImageUrl = dataUrl;
        _featuredImageFile = null;
        _featuredImageBytes = null;
      });
    }
  }

  void _pickAdditionalImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      final List<String> newDataUrls = [];
      for (final img in images) {
        final bytes = kIsWeb ? await img.readAsBytes() : await File(img.path).readAsBytes();
        final lower = img.name.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        newDataUrls.add('data:$mime;base64,${base64Encode(bytes)}');
      }
      setState(() {
        _imageUrls.addAll(newDataUrls);
        _galleryImageFiles.clear();
        _galleryImageBytes.clear();
      });
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
      
      // Create a temp ID for pathing uploads when creating
      final generatedId = DateTime.now().millisecondsSinceEpoch.toString();
      final titleId = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim().replaceAll(' ', '_').toLowerCase()
          : generatedId;
      final provisionalPostId = _sanitizeStorageId(widget.existingPost?.id ?? titleId);

      // No uploads: images are already embedded as base64 data URLs

      // No uploads: gallery images already encoded as data URLs

      final readTimeValue = int.tryParse(_readTimeController.text.trim()) ?? 3;
      
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
        readTime: readTimeValue,
        viewCount: widget.existingPost?.viewCount ?? 0,
        likeCount: widget.existingPost?.likeCount ?? 0,
        isPublished: publish,
        publishedAt: publish ? now : (widget.existingPost?.publishedAt ?? now),
        createdAt: widget.existingPost?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existingPost != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating post...')));
        await blogService.updateBlogPost(post);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creating post...')));
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
