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
        title: Text(widget.successStory != null ? 'Edit Success Story' : 'Add Success Story'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveSuccessStory,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Story Images Section
              _buildImageSection(),
              const SizedBox(height: 20),

              // Story Information
              _buildSectionTitle('Story Information'),
              const SizedBox(height: 12),
              _buildStoryInformationSection(),

              const SizedBox(height: 20),

              // Pet and Adopter Information
              _buildSectionTitle('Pet and Adopter Information'),
              const SizedBox(height: 12),
              _buildPetAdopterInformationSection(),

              const SizedBox(height: 20),

              // Featured Status
              _buildSectionTitle('Featured Status'),
              const SizedBox(height: 12),
              _buildFeaturedStatusSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Story Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Existing photos
        if (_photoUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _photoUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _photoUrls.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
          const SizedBox(height: 8),
        ],
        // Add photos button
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Photos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${_selectedImages.length} image(s) selected for upload'),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStoryInformationSection() {
    return Column(
      children: [
        TextFormField(
          controller: _storyTitleController,
          decoration: const InputDecoration(
            labelText: 'Story Title *',
            border: OutlineInputBorder(),
            hintText: 'e.g., "Max found his forever home"',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter story title';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _storyDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Story Description *',
            border: OutlineInputBorder(),
            hintText: 'Tell the heartwarming story of this adoption...',
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter story description';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Adoption Date'),
          subtitle: Text(_adoptionDate != null 
              ? '${_adoptionDate!.day}/${_adoptionDate!.month}/${_adoptionDate!.year}'
              : 'Not set'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _adoptionDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _adoptionDate = date);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPetAdopterInformationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _petNameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pet name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _petTypeController,
                decoration: const InputDecoration(
                  labelText: 'Pet Type *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Dog, Cat',
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _adopterNameController,
                decoration: const InputDecoration(
                  labelText: 'Adopter Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter adopter name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _adopterEmailController,
                decoration: const InputDecoration(
                  labelText: 'Adopter Email *',
                  border: OutlineInputBorder(),
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
    );
  }

  Widget _buildFeaturedStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Featured Story'),
              subtitle: const Text('Featured stories are shown to all users'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
              activeColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
