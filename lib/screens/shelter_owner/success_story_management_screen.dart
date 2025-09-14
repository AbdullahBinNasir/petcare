import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/success_story_service.dart';
import '../../models/success_story_model.dart';
import 'add_edit_success_story_screen.dart';

class SuccessStoryManagementScreen extends StatefulWidget {
  const SuccessStoryManagementScreen({super.key});

  @override
  State<SuccessStoryManagementScreen> createState() => _SuccessStoryManagementScreenState();
}

class _SuccessStoryManagementScreenState extends State<SuccessStoryManagementScreen> {
  late String _shelterOwnerId;
  List<SuccessStoryModel> _successStories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _shelterOwnerId = authService.currentUserModel?.id ?? '';
    _loadSuccessStories();
  }

  Future<void> _loadSuccessStories() async {
    setState(() => _isLoading = true);
    try {
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final successStories = await successStoryService.getSuccessStoriesByShelterOwnerId(_shelterOwnerId);
      setState(() {
        _successStories = successStories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading success stories: $e');
    }
  }

  Future<void> _searchSuccessStories() async {
    setState(() => _isLoading = true);
    try {
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final successStories = await successStoryService.searchSuccessStories(
        query: _searchQuery,
        shelterOwnerId: _shelterOwnerId,
      );
      setState(() {
        _successStories = successStories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error searching success stories: $e');
    }
  }

  Future<void> _deleteSuccessStory(String storyId) async {
    try {
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final success = await successStoryService.deleteSuccessStory(storyId);
      if (success) {
        _loadSuccessStories();
        _showSuccessSnackBar('Success story deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete success story');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting success story: $e');
    }
  }

  Future<void> _toggleFeaturedStatus(String storyId, bool isFeatured) async {
    try {
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final success = await successStoryService.updateSuccessStoryFeaturedStatus(storyId, isFeatured);
      if (success) {
        _loadSuccessStories();
        _showSuccessSnackBar('Success story featured status updated');
      } else {
        _showErrorSnackBar('Failed to update featured status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating featured status: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuccessStories,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search success stories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadSuccessStories();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  _loadSuccessStories();
                } else {
                  _searchSuccessStories();
                }
              },
            ),
          ),
          // Success Stories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _successStories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No success stories found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Add your first success story to inspire others',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _successStories.length,
                        itemBuilder: (context, index) {
                          final story = _successStories[index];
                          return _buildSuccessStoryCard(story);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditSuccessStoryScreen(),
            ),
          );
          if (result == true) {
            _loadSuccessStories();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSuccessStoryCard(SuccessStoryModel story) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Story Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: story.photoUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            story.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.celebration,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.celebration,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 16),
                // Story Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              story.storyTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (story.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.petName} adopted by ${story.adopterName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adopted ${story.timeSinceAdoption}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editSuccessStory(story);
                        break;
                      case 'feature':
                        _toggleFeaturedStatus(story.id, !story.isFeatured);
                        break;
                      case 'delete':
                        _showDeleteDialog(story);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'feature',
                      child: Row(
                        children: [
                          Icon(
                            story.isFeatured ? Icons.star_border : Icons.star,
                            size: 20,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(story.isFeatured ? 'Remove from Featured' : 'Mark as Featured'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              story.storyDescription,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _editSuccessStory(SuccessStoryModel story) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSuccessStoryScreen(successStory: story),
      ),
    );
    if (result == true) {
      _loadSuccessStories();
    }
  }

  void _showDeleteDialog(SuccessStoryModel story) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Success Story'),
          content: Text('Are you sure you want to delete "${story.storyTitle}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSuccessStory(story.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
