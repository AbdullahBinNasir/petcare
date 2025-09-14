import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../services/bookmark_service.dart';
import '../../services/auth_service.dart';
import '../../models/bookmark_model.dart';
import '../../models/blog_post_model.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  Set<String> _selectedBookmarks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookmarks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
    
    if (authService.currentUserModel != null) {
      await bookmarkService.loadUserBookmarks(authService.currentUserModel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select Bookmarks' : 'My Bookmarks'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedBookmarks.isNotEmpty ? _deleteSelected : null,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedBookmarks.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
          ],
        ],
      ),
      body: Consumer2<BookmarkService, AuthService>(
        builder: (context, bookmarkService, authService, child) {
          if (authService.currentUserModel == null) {
            return const Center(
              child: Text('Please log in to view your bookmarks'),
            );
          }

          if (bookmarkService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookmarkService.bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchAndFilters(bookmarkService),
              _buildStats(bookmarkService),
              Expanded(
                child: _buildBookmarksList(bookmarkService, authService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookmarks Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start bookmarking articles you want to read later',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BookmarkService bookmarkService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search bookmarks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        bookmarkService.searchBookmarks('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              bookmarkService.searchBookmarks(value);
            },
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', bookmarkService.filterBy),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', 'unread', bookmarkService.filterBy),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress', bookmarkService.filterBy),
                const SizedBox(width: 8),
                _buildFilterChip('Read', 'read', bookmarkService.filterBy),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Sort Options
          Row(
            children: [
              const Text('Sort by: '),
              DropdownButton<String>(
                value: bookmarkService.sortBy,
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Recent')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                  DropdownMenuItem(value: 'progress', child: Text('Progress')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    bookmarkService.sortBookmarks(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentFilter) {
    return FilterChip(
      label: Text(label),
      selected: currentFilter == value,
      onSelected: (selected) {
        if (selected) {
          Provider.of<BookmarkService>(context, listen: false)
              .filterByReadStatus(value);
        }
      },
    );
  }

  Widget _buildStats(BookmarkService bookmarkService) {
    final stats = bookmarkService.getReadingStats();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['totalBookmarks'].toString(), Icons.bookmark),
          _buildStatItem('Read', stats['readBookmarks'].toString(), Icons.check_circle),
          _buildStatItem('Progress', stats['inProgressBookmarks'].toString(), Icons.trending_up),
          _buildStatItem('Unread', stats['unreadBookmarks'].toString(), Icons.circle_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarksList(BookmarkService bookmarkService, AuthService authService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarkService.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarkService.bookmarks[index];
        return _buildBookmarkCard(bookmark, bookmarkService, authService);
      },
    );
  }

  Widget _buildBookmarkCard(BookmarkModel bookmark, BookmarkService bookmarkService, AuthService authService) {
    final isSelected = _selectedBookmarks.contains(bookmark.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isSelectionMode ? () => _toggleSelection(bookmark.id) : () => _openBookmark(bookmark),
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedBookmarks.add(bookmark.id);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleSelection(bookmark.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Bookmark Image
                  if (bookmark.postImageUrl != null && bookmark.postImageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        child: _buildImageWidget(bookmark.postImageUrl!),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.postTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookmark.postExcerpt,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleBookmarkAction(value, bookmark, bookmarkService, authService),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new),
                              SizedBox(width: 8),
                              Text('Open'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'notes',
                          child: Row(
                            children: [
                              Icon(Icons.note_add),
                              SizedBox(width: 8),
                              Text('Add Notes'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_remove),
                              SizedBox(width: 8),
                              Text('Remove'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tags and Category
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(bookmark.postCategory),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  ...bookmark.postTags.take(3).map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[200],
                  )),
                ],
              ),
              const SizedBox(height: 8),
              
              // Progress and Status
              Row(
                children: [
                  Icon(
                    bookmark.isRead ? Icons.check_circle : 
                    bookmark.readProgress > 0 ? Icons.trending_up : Icons.circle_outlined,
                    size: 16,
                    color: bookmark.isRead ? Colors.green : 
                           bookmark.readProgress > 0 ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bookmark.readStatus,
                    style: TextStyle(
                      color: bookmark.isRead ? Colors.green : 
                             bookmark.readProgress > 0 ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${bookmark.postReadTime} min read',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Progress Bar
              if (bookmark.readProgress > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: bookmark.readProgress / 100,
                  backgroundColor: Colors.grey[300],
                ),
              ],
              
              // Notes
              if (bookmark.notes != null && bookmark.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.notes!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Bookmark Date
              const SizedBox(height: 8),
              Text(
                'Bookmarked ${bookmark.formattedBookmarkDate}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String bookmarkId) {
    setState(() {
      if (_selectedBookmarks.contains(bookmarkId)) {
        _selectedBookmarks.remove(bookmarkId);
      } else {
        _selectedBookmarks.add(bookmarkId);
      }
    });
  }

  void _openBookmark(BookmarkModel bookmark) {
    // Navigate to blog post detail screen
    // This would typically open the full article
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: ${bookmark.postTitle}')),
    );
  }

  void _handleBookmarkAction(String action, BookmarkModel bookmark, BookmarkService bookmarkService, AuthService authService) {
    switch (action) {
      case 'open':
        _openBookmark(bookmark);
        break;
      case 'notes':
        _showNotesDialog(bookmark, bookmarkService);
        break;
      case 'remove':
        _removeBookmark(bookmark, bookmarkService, authService);
        break;
    }
  }

  void _showNotesDialog(BookmarkModel bookmark, BookmarkService bookmarkService) {
    final controller = TextEditingController(text: bookmark.notes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add your notes about this article...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bookmarkService.addNotes(bookmark.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeBookmark(BookmarkModel bookmark, BookmarkService bookmarkService, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: Text('Are you sure you want to remove "${bookmark.postTitle}" from your bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await bookmarkService.removeBookmark(authService.currentUserModel!.id, bookmark.postId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${_selectedBookmarks.length} bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
              await bookmarkService.bulkDeleteBookmarks(_selectedBookmarks.toList());
              setState(() {
                _isSelectionMode = false;
                _selectedBookmarks.clear();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        final base64Part = imageUrl.split(',').last;
        final bytes = base64Part.isNotEmpty ? base64Decode(base64Part) : null;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 32),
            ),
          );
        }
      }
    } catch (_) {}

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 32),
      ),
    );
  }
}
