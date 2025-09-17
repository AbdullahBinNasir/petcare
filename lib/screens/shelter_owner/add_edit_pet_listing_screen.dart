import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';
import '../../utils/image_utils.dart';

class AddEditPetListingScreen extends StatefulWidget {
  final PetListingModel? petListing;

  const AddEditPetListingScreen({super.key, this.petListing});

  @override
  State<AddEditPetListingScreen> createState() => _AddEditPetListingScreenState();
}

class _AddEditPetListingScreenState extends State<AddEditPetListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipIdController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specialNeedsController = TextEditingController();

  PetListingType _selectedType = PetListingType.dog;
  PetListingGender _selectedGender = PetListingGender.unknown;
  HealthStatus _selectedHealthStatus = HealthStatus.healthy;
  PetListingStatus _selectedStatus = PetListingStatus.available;
  bool _isVaccinated = false;
  bool _isSpayedNeutered = false;
  DateTime? _dateArrived;
  List<String> _photoUrls = [];
  List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.petListing != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final petListing = widget.petListing!;
    _nameController.text = petListing.name;
    _breedController.text = petListing.breed;
    _ageController.text = petListing.age.toString();
    _weightController.text = petListing.weight?.toString() ?? '';
    _colorController.text = petListing.color ?? '';
    _microchipIdController.text = petListing.microchipId ?? '';
    _medicalNotesController.text = petListing.medicalNotes ?? '';
    _descriptionController.text = petListing.description ?? '';
    _specialNeedsController.text = petListing.specialNeeds ?? '';
    _selectedType = petListing.type;
    _selectedGender = petListing.gender;
    _selectedHealthStatus = petListing.healthStatus;
    _selectedStatus = petListing.status;
    _isVaccinated = petListing.isVaccinated;
    _isSpayedNeutered = petListing.isSpayedNeutered;
    _dateArrived = petListing.dateArrived;
    _photoUrls = List.from(petListing.photoUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipIdController.dispose();
    _medicalNotesController.dispose();
    _descriptionController.dispose();
    _specialNeedsController.dispose();
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

    final petListingService = Provider.of<PetListingService>(context, listen: false);
    final tempId = widget.petListing?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    for (final image in _selectedImages) {
      try {
        // Convert to base64 using the new method
        final xFile = XFile(image.path);
        final base64DataUrl = await petListingService.uploadPetListingPhotoFromXFile(xFile, tempId);
        if (base64DataUrl != null && base64DataUrl.isNotEmpty) {
          _photoUrls.add(base64DataUrl);
          print('✅ Converted pet listing image to base64: ${base64DataUrl.substring(0, 50)}...');
        } else {
          // Fallback to Firebase Storage upload
          final photoUrl = await petListingService.uploadPetListingPhoto(image, tempId);
          if (photoUrl != null) {
            _photoUrls.add(photoUrl);
          }
        }
      } catch (e) {
        print('❌ Error converting image to base64: $e');
        // Fallback to Firebase Storage upload
        final photoUrl = await petListingService.uploadPetListingPhoto(image, tempId);
        if (photoUrl != null) {
          _photoUrls.add(photoUrl);
        }
      }
    }
  }

  Future<void> _savePetListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images first
      await _uploadImages();

      final authService = Provider.of<AuthService>(context, listen: false);
      final shelterOwnerId = authService.currentUserModel?.id ?? '';

      final petListing = PetListingModel(
        id: widget.petListing?.id ?? '',
        shelterOwnerId: shelterOwnerId,
        name: _nameController.text.trim(),
        type: _selectedType,
        breed: _breedController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_ageController.text) ?? 0,
        weight: double.tryParse(_weightController.text),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        microchipId: _microchipIdController.text.trim().isEmpty ? null : _microchipIdController.text.trim(),
        photoUrls: _photoUrls,
        healthStatus: _selectedHealthStatus,
        medicalNotes: _medicalNotesController.text.trim().isEmpty ? null : _medicalNotesController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        specialNeeds: _specialNeedsController.text.trim().isEmpty ? null : _specialNeedsController.text.trim(),
        isVaccinated: _isVaccinated,
        isSpayedNeutered: _isSpayedNeutered,
        status: _selectedStatus,
        dateArrived: _dateArrived,
        createdAt: widget.petListing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final petListingService = Provider.of<PetListingService>(context, listen: false);
      
      if (widget.petListing != null) {
        // Update existing pet listing
        final success = await petListingService.updatePetListing(petListing);
        if (success) {
          _showSuccessSnackBar('Pet listing updated successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to update pet listing');
        }
      } else {
        // Add new pet listing
        final listingId = await petListingService.addPetListing(petListing);
        if (listingId != null) {
          _showSuccessSnackBar('Pet listing added successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to add pet listing');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error saving pet listing: $e');
    } finally {
      setState(() => _isLoading = false);
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
        title: Text(
          widget.petListing != null ? 'Edit Pet Listing' : 'Add Pet Listing',
          style: const TextStyle(
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
          if (_isLoading)
            Container(
              margin: const EdgeInsets.all(16.0),
              width: 24,
              height: 24,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFAFAF0),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _savePetListing,
                icon: const Icon(
                  Icons.save_rounded,
                  color: Color(0xFFFAFAF0),
                  size: 20,
                ),
                label: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFFFAFAF0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFAFAF0).withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
              // Pet Images Section
              _buildImageSection(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionCard(
                'Basic Information',
                Icons.pets_rounded,
                _buildBasicInformationSection(),
              ),

              const SizedBox(height: 16),

              // Health Information
              _buildSectionCard(
                'Health Information',
                Icons.medical_services_rounded,
                _buildHealthInformationSection(),
              ),

              const SizedBox(height: 16),

              // Additional Information
              _buildSectionCard(
                'Additional Information',
                Icons.description_rounded,
                _buildAdditionalInformationSection(),
              ),

              const SizedBox(height: 16),

              // Status Information
              _buildSectionCard(
                'Status Information',
                Icons.info_rounded,
                _buildStatusInformationSection(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7D4D20),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7D4D20),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D4D20).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF7D4D20),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pet Photos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7D4D20),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Existing photos
            if (_photoUrls.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF7D4D20).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _photoUrls[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 120,
                                  height: 120,
                                  color: const Color(0xFFFAFAF0),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    color: const Color(0xFF7D4D20).withOpacity(0.5),
                                  ),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC143C),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFFAFAF0),
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
              const SizedBox(height: 16),
            ],
            
            // Add photos button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7D4D20).withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickImages,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7D4D20).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 32,
                            color: const Color(0xFF7D4D20).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7D4D20).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select photos from gallery',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF7D4D20).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF228B22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFF228B22),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedImages.length} image(s) selected for upload',
                      style: const TextStyle(
                        color: Color(0xFF228B22),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                controller: _nameController,
                label: 'Pet Name *',
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
              child: _buildStyledDropdown<PetListingType>(
                value: _selectedType,
                label: 'Type *',
                items: PetListingType.values,
                onChanged: (value) => setState(() => _selectedType = value!),
                itemBuilder: (type) => type.toString().split('.').last,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                controller: _breedController,
                label: 'Breed *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter breed';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStyledTextField(
                controller: _ageController,
                label: 'Age (months) *',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid age';
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
              child: _buildStyledDropdown<PetListingGender>(
                value: _selectedGender,
                label: 'Gender *',
                items: PetListingGender.values,
                onChanged: (value) => setState(() => _selectedGender = value!),
                itemBuilder: (gender) => gender.toString().split('.').last,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStyledTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStyledTextField(
          controller: _colorController,
          label: 'Color',
        ),
      ],
    );
  }

  Widget _buildHealthInformationSection() {
    return Column(
      children: [
        _buildStyledDropdown<HealthStatus>(
          value: _selectedHealthStatus,
          label: 'Health Status *',
          items: HealthStatus.values,
          onChanged: (value) => setState(() => _selectedHealthStatus = value!),
          itemBuilder: (status) => status.toString().split('.').last,
        ),
        const SizedBox(height: 16),
        _buildStyledTextField(
          controller: _medicalNotesController,
          label: 'Medical Notes',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStyledCheckbox(
                'Vaccinated',
                _isVaccinated,
                (value) => setState(() => _isVaccinated = value ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStyledCheckbox(
                'Spayed/Neutered',
                _isSpayedNeutered,
                (value) => setState(() => _isSpayedNeutered = value ?? false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInformationSection() {
    return Column(
      children: [
        _buildStyledTextField(
          controller: _descriptionController,
          label: 'Description',
          hintText: 'Tell potential adopters about this pet...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildStyledTextField(
          controller: _specialNeedsController,
          label: 'Special Needs',
          hintText: 'Any special care requirements...',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildStyledTextField(
          controller: _microchipIdController,
          label: 'Microchip ID',
        ),
      ],
    );
  }

  Widget _buildStatusInformationSection() {
    return Column(
      children: [
        _buildStyledDropdown<PetListingStatus>(
          value: _selectedStatus,
          label: 'Status *',
          items: PetListingStatus.values,
          onChanged: (value) => setState(() => _selectedStatus = value!),
          itemBuilder: (status) => status.toString().split('.').last,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAF0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7D4D20).withOpacity(0.2),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7D4D20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFF7D4D20),
                size: 20,
              ),
            ),
            title: const Text(
              'Date Arrived at Shelter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF7D4D20),
              ),
            ),
            subtitle: Text(
              _dateArrived != null 
                  ? '${_dateArrived!.day}/${_dateArrived!.month}/${_dateArrived!.year}'
                  : 'Tap to set arrival date',
              style: TextStyle(
                color: const Color(0xFF7D4D20).withOpacity(0.7),
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateArrived ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF7D4D20),
                        onPrimary: Color(0xFFFAFAF0),
                        surface: Color(0xFFFAFAF0),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _dateArrived = date);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7D4D20).withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7D4D20)),
          hintText: hintText,
          hintStyle: TextStyle(color: const Color(0xFF7D4D20).withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: const TextStyle(color: Color(0xFF7D4D20)),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7D4D20).withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7D4D20)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        dropdownColor: const Color(0xFFFAFAF0),
        style: const TextStyle(color: Color(0xFF7D4D20)),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder(item)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStyledCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7D4D20).withOpacity(0.2),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7D4D20),
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7D4D20),
        checkColor: const Color(0xFFFAFAF0),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}