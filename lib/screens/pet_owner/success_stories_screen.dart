import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/success_story_service.dart';
import '../../models/success_story_model.dart';
import '../../theme/pet_care_theme.dart';
import '../../widgets/universal_image_widget.dart';
import '../../utils/success_story_image_helper.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  List<SuccessStoryModel> _successStories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuccessStories();
  }

  Future<void> _loadSuccessStories() async {
    setState(() => _isLoading = true);
    try {
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final successStories = await successStoryService.getAllPublicSuccessStories();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PetCareTheme.warmRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestImagesToStories,
        backgroundColor: PetCareTheme.primaryBrown,
        child: const Icon(Icons.image, color: Colors.white),
        tooltip: 'Add Test Images to Stories',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchSection(),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _successStories.isEmpty
                            ? _buildEmptyState()
                            : _buildSuccessStoriesList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: PetCareTheme.primaryBeige,
                  size: 24,
                ),
              ),
              Expanded(
                child: Text(
                  'Success Stories',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBeige,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => _loadSuccessStories(),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: PetCareTheme.primaryBeige,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search success stories...',
          hintStyle: TextStyle(
            color: PetCareTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: PetCareTheme.primaryBrown,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: PetCareTheme.primaryBrown,
                  ),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _loadSuccessStories();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: PetCareTheme.primaryBeige.withOpacity( 0.05),
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite.withOpacity( 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBrown),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Success Stories...',
              style: TextStyle(
                color: PetCareTheme.primaryBrown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [PetCareTheme.elevatedShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PetCareTheme.primaryBrown.withOpacity( 0.1),
                    PetCareTheme.lightBrown.withOpacity( 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 50,
                color: PetCareTheme.primaryBrown.withOpacity( 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Success Stories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for inspiring adoption stories',
              style: TextStyle(
                fontSize: 16,
                color: PetCareTheme.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _successStories.length,
      itemBuilder: (context, index) {
        final story = _successStories[index];
        return _buildSuccessStoryCard(story);
      },
    );
  }

  Widget _buildSuccessStoryCard(SuccessStoryModel story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: story.isFeatured 
              ? PetCareTheme.accentGold.withOpacity( 0.3)
              : PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: story.isFeatured ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          if (story.isFeatured)
            BoxShadow(
              color: PetCareTheme.accentGold.withOpacity( 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewStoryDetails(story),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          PetCareTheme.primaryBeige.withOpacity( 0.1),
                          PetCareTheme.lightBrown.withOpacity( 0.1),
                        ],
                      ),
                    ),
                    child: story.photoUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: UniversalImageWidget(
                              imageUrl: story.photoUrls.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: Icon(
                                Icons.celebration_rounded,
                                size: 40,
                                color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.celebration_rounded,
                            size: 40,
                            color: PetCareTheme.primaryBrown.withOpacity( 0.6),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: PetCareTheme.textDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (story.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PetCareTheme.shadowColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${story.petName} adopted by ${story.adopterName}',
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adopted ${story.timeSinceAdoption}',
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PetCareTheme.primaryBeige.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PetCareTheme.primaryBeige.withOpacity( 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: PetCareTheme.primaryBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        story.storyDescription,
                        style: TextStyle(
                          color: PetCareTheme.textLight,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewStoryDetails(SuccessStoryModel story) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [PetCareTheme.elevatedShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        story.storyTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: PetCareTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (story.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: PetCareTheme.shadowColor,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Story Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PetCareTheme.primaryBeige.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PetCareTheme.primaryBeige.withOpacity( 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${story.petName} adopted by ${story.adopterName}',
                        style: TextStyle(
                          color: PetCareTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adopted ${story.timeSinceAdoption}',
                        style: TextStyle(
                          color: PetCareTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (story.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: PetCareTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PageView.builder(
                        itemCount: story.photoUrls.length,
                        itemBuilder: (context, index) {
                          return UniversalImageWidget(
                            imageUrl: story.photoUrls[index],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: PetCareTheme.primaryBeige.withOpacity( 0.1),
                              child: Icon(
                                Icons.error_rounded,
                                size: 50,
                                color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PetCareTheme.lightBrown.withOpacity( 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PetCareTheme.lightBrown.withOpacity( 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success Story',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PetCareTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story.storyDescription,
                        style: TextStyle(
                          color: PetCareTheme.textLight,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: PetCareTheme.shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addTestImagesToStories() async {
    try {
      if (_successStories.isNotEmpty) {
        for (int i = 0; i < _successStories.length; i++) {
          final story = _successStories[i];
          final base64Image = SuccessStoryImageHelper.createColoredBase64Image('story_$i');
          
          await SuccessStoryImageHelper.addBase64ImageToSuccessStory(story.id, base64Image);
          print('✅ Added base64 image to story ${i + 1}: ${story.storyTitle}');
        }
        
        // Reload data to show the new images
        _loadSuccessStories();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base64 images added to all success stories!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding base64 images to stories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
