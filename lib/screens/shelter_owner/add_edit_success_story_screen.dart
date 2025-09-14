import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/success_story_service.dart';
import '../../models/success_story_model.dart';

class AddEditSuccessStoryScreen extends StatefulWidget {
  final SuccessStoryModel? successStory;

  const AddEditSuccessStoryScreen({super.key, this.successStory});

  @override
  State<AddEditSuccessStoryScreen> createState() => _AddEditSuccessStoryScreenState();
}

class _AddEditSuccessStoryScreenState extends State<AddEditSuccessStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _adopterNameController = TextEditingController();
  final _adopterEmailController = TextEditingController();
  final _storyTitleController = TextEditingController();
  final _storyDescriptionController = TextEditingController();

  DateTime? _adoptionDate;
  List<String> _photoUrls = [];
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isFeatured = false;

  // Custom color scheme
  static const Color primaryColor = Color(0xFF7d4d20);
  static const Color backgroundColor = Color(0xFFfafaf0);
  static const Color cardColor = Color(0xFFfefefe);
  static const Color accentColor = Color(0xFF9d6d40);

  @override
  void initState() {
    super.initState();
    if (widget.successStory != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final story = widget.successStory!;
    _petNameController.text = story.petName;
    _petTypeController.text = story.petType;
    _adopterNameController.text = story.adopterName;
    _adopterEmailController.text = story.adopterEmail;
    _storyTitleController.text = story.storyTitle;
    _storyDescriptionController.text = story.storyDescription;
    _adoptionDate = story.adoptionDate;
    _photoUrls = List.from(story.photoUrls);
    _isFeatured = story.isFeatured;
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _petTypeController.dispose();
    _adopterNameController.dispose();
    _adopterEmailController.dispose();
    _storyTitleController.dispose();
    _storyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
    final tempId = widget.successStory?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    for (final image in _selectedImages) {
      final photoUrl = await successStoryService.uploadSuccessStoryPhoto(image, tempId);
      if (photoUrl != null) {
        _photoUrls.add(photoUrl);
      }
    }
  }

  Future<void> _saveSuccessStory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images first
      await _uploadImages();

      final authService = Provider.of<AuthService>(context, listen: false);
      final shelterOwnerId = authService.currentUserModel?.id ?? '';

      final successStory = SuccessStoryModel(
        id: widget.successStory?.id ?? '',
        shelterOwnerId: shelterOwnerId,
        petName: _petNameController.text.trim(),
        petType: _petTypeController.text.trim(),
        adopterName: _adopterNameController.text.trim(),
        adopterEmail: _adopterEmailController.text.trim(),
        storyTitle: _storyTitleController.text.trim(),
        storyDescription: _storyDescriptionController.text.trim(),
        photoUrls: _photoUrls,
        adoptionDate: _adoptionDate ?? DateTime.now(),
        createdAt: widget.successStory?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: _isFeatured,
      );

      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      
      if (widget.successStory != null) {
        // Update existing success story
        final success = await successStoryService.updateSuccessStory(successStory);
        if (success) {
          _showSuccessSnackBar('Success story updated successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to update success story');
        }
      } else {
        // Add new success story
        final storyId = await successStoryService.addSuccessStory(successStory);
        if (storyId != null) {
          _showSuccessSnackBar('Success story added successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to add success story');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error saving success story: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.successStory != null ? 'Edit Success Story' : 'Add Success Story',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFfafaf0),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _saveSuccessStory,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: backgroundColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Story Images Section
              _buildImageSection(),
              const SizedBox(height: 24),

              // Story Information
              _buildStoryInformationSection(),
              const SizedBox(height: 24),

              // Pet and Adopter Information
              _buildPetAdopterInformationSection(),
              const SizedBox(height: 24),

              // Featured Status
              _buildFeaturedStatusSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Story Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2d2d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Existing photos
          if (_photoUrls.isNotEmpty) ...[
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withOpacity(0.2)),
                            ),
                            child: Image.network(
                              _photoUrls[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.error, color: primaryColor),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Add photos button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedImages.length} image(s) selected for upload',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryInformationSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Story Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2d2d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _storyTitleController,
            decoration: InputDecoration(
              labelText: 'Story Title *',
              labelStyle: TextStyle(color: primaryColor),
              hintText: 'e.g., "Max found his forever home"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: backgroundColor.withOpacity(0.5),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter story title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _storyDescriptionController,
            decoration: InputDecoration(
              labelText: 'Story Description *',
              labelStyle: TextStyle(color: primaryColor),
              hintText: 'Tell the heartwarming story of this adoption...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: backgroundColor.withOpacity(0.5),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter story description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
              color: backgroundColor.withOpacity(0.5),
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: primaryColor),
              title: const Text('Adoption Date', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _adoptionDate != null 
                    ? '${_adoptionDate!.day}/${_adoptionDate!.month}/${_adoptionDate!.year}'
                    : 'Tap to select date',
                style: TextStyle(color: primaryColor.withOpacity(0.8)),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _adoptionDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          onPrimary: backgroundColor,
                          surface: cardColor,
                          onSurface: primaryColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _adoptionDate = date);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAdopterInformationSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Pet & Adopter Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2d2d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _petNameController,
                  decoration: InputDecoration(
                    labelText: 'Pet Name *',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pet name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _petTypeController,
                  decoration: InputDecoration(
                    labelText: 'Pet Type *',
                    labelStyle: TextStyle(color: primaryColor),
                    hintText: 'e.g., Dog, Cat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pet type';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adopterNameController,
                  decoration: InputDecoration(
                    labelText: 'Adopter Name *',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter adopter name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _adopterEmailController,
                  decoration: InputDecoration(
                    labelText: 'Adopter Email *',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.5),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter adopter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStatusSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Featured Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2d2d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor.withOpacity(0.5),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Featured Story',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Featured stories are shown to all users'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
              activeColor: Colors.amber.shade600,
              activeTrackColor: Colors.amber.shade200,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
              secondary: Icon(
                _isFeatured ? Icons.star : Icons.star_border,
                color: _isFeatured ? Colors.amber.shade600 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}