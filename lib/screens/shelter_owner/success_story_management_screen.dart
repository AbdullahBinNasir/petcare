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
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFFFAFAF0))),
        backgroundColor: const Color(0xFFDC143C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFFFAFAF0))),
        backgroundColor: const Color(0xFF228B22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF0),
      appBar: AppBar(
        title: const Text(
          'Success Stories Management',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF7D4D20),
        foregroundColor: const Color(0xFFFAFAF0),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFAFAF0)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadSuccessStories,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7D4D20).withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7D4D20).withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search success stories...',
                    hintStyle: TextStyle(color: const Color(0xFF7D4D20).withOpacity(0.6)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF7D4D20).withOpacity(0.7),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7D4D20).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              color: const Color(0xFF7D4D20),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _loadSuccessStories();
                              },
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: Color(0xFF7D4D20)),
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
            ),
          ),
          // Success Stories List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7D4D20),
                      strokeWidth: 3,
                    ),
                  )
                : _successStories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7D4D20).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.celebration_outlined,
                                size: 64,
                                color: const Color(0xFF7D4D20).withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No success stories found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7D4D20),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first success story to inspire others',
                              style: TextStyle(
                                color: const Color(0xFF7D4D20).withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _successStories.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final story = _successStories[index];
                          return _buildSuccessStoryCard(story);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7D4D20),
              const Color(0xFF7D4D20).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7D4D20).withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: FloatingActionButton(
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFFFAFAF0),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStoryCard(SuccessStoryModel story) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D4D20).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Story Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF7D4D20).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: story.photoUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            story.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.celebration_rounded,
                              size: 40,
                              color: const Color(0xFF7D4D20).withOpacity(0.6),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.celebration_rounded,
                          size: 40,
                          color: const Color(0xFF7D4D20).withOpacity(0.6),
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
                                color: Color(0xFF7D4D20),
                              ),
                            ),
                          ),
                          if (story.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: const Color(0xFF7D4D20),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Featured',
                                    style: TextStyle(
                                      color: Color(0xFF7D4D20),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAF0).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${story.petName} adopted by ${story.adopterName}',
                          style: TextStyle(
                            color: const Color(0xFF7D4D20).withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adopted ${story.timeSinceAdoption}',
                        style: TextStyle(
                          color: const Color(0xFF7D4D20).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Menu Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: const Color(0xFF7D4D20),
                    ),
                    color: const Color(0xFFFAFAF0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4169E1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Color(0xFF4169E1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Edit',
                              style: TextStyle(color: Color(0xFF7D4D20)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'feature',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                story.isFeatured ? Icons.star_border_rounded : Icons.star_rounded,
                                size: 16,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              story.isFeatured ? 'Remove Featured' : 'Mark Featured',
                              style: const TextStyle(color: Color(0xFF7D4D20)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC143C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: Color(0xFFDC143C),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Color(0xFFDC143C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAF0).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7D4D20).withOpacity(0.1),
                ),
              ),
              child: Text(
                story.storyDescription,
                style: TextStyle(
                  color: const Color(0xFF7D4D20).withOpacity(0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
          backgroundColor: const Color(0xFFFAFAF0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC143C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Success Story',
                style: TextStyle(
                  color: Color(0xFF7D4D20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                color: const Color(0xFF7D4D20).withOpacity(0.8),
                fontSize: 16,
              ),
              children: [
                const TextSpan(text: 'Are you sure you want to delete "'),
                TextSpan(
                  text: story.storyTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '"?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7D4D20).withOpacity(0.7),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSuccessStory(story.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: const Color(0xFFFAFAF0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}