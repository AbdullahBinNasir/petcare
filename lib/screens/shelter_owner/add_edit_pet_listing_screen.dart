import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';

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
      final photoUrl = await petListingService.uploadPetListingPhoto(image, tempId);
      if (photoUrl != null) {
        _photoUrls.add(photoUrl);
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
        title: Text(widget.petListing != null ? 'Edit Pet Listing' : 'Add Pet Listing'),
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
              onPressed: _savePetListing,
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
              // Pet Images Section
              _buildImageSection(),
              const SizedBox(height: 20),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildBasicInformationSection(),

              const SizedBox(height: 20),

              // Health Information
              _buildSectionTitle('Health Information'),
              const SizedBox(height: 12),
              _buildHealthInformationSection(),

              const SizedBox(height: 20),

              // Additional Information
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 12),
              _buildAdditionalInformationSection(),

              const SizedBox(height: 20),

              // Status Information
              _buildSectionTitle('Status Information'),
              const SizedBox(height: 12),
              _buildStatusInformationSection(),

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
          'Pet Photos',
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

  Widget _buildBasicInformationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
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
              child: DropdownButtonFormField<PetListingType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(),
                ),
                items: PetListingType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed *',
                  border: OutlineInputBorder(),
                ),
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
              child: TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age (months) *',
                  border: OutlineInputBorder(),
                ),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PetListingGender>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                items: PetListingGender.values.map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender.toString().split('.').last),
                )).toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _colorController,
          decoration: const InputDecoration(
            labelText: 'Color',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthInformationSection() {
    return Column(
      children: [
        DropdownButtonFormField<HealthStatus>(
          value: _selectedHealthStatus,
          decoration: const InputDecoration(
            labelText: 'Health Status *',
            border: OutlineInputBorder(),
          ),
          items: HealthStatus.values.map((status) => DropdownMenuItem(
            value: status,
            child: Text(status.toString().split('.').last),
          )).toList(),
          onChanged: (value) => setState(() => _selectedHealthStatus = value!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _medicalNotesController,
          decoration: const InputDecoration(
            labelText: 'Medical Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Vaccinated'),
                value: _isVaccinated,
                onChanged: (value) => setState(() => _isVaccinated = value ?? false),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Spayed/Neutered'),
                value: _isSpayedNeutered,
                onChanged: (value) => setState(() => _isSpayedNeutered = value ?? false),
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
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            hintText: 'Tell potential adopters about this pet...',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _specialNeedsController,
          decoration: const InputDecoration(
            labelText: 'Special Needs',
            border: OutlineInputBorder(),
            hintText: 'Any special care requirements...',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _microchipIdController,
          decoration: const InputDecoration(
            labelText: 'Microchip ID',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInformationSection() {
    return Column(
      children: [
        DropdownButtonFormField<PetListingStatus>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status *',
            border: OutlineInputBorder(),
          ),
          items: PetListingStatus.values.map((status) => DropdownMenuItem(
            value: status,
            child: Text(status.toString().split('.').last),
          )).toList(),
          onChanged: (value) => setState(() => _selectedStatus = value!),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Date Arrived at Shelter'),
          subtitle: Text(_dateArrived != null 
              ? '${_dateArrived!.day}/${_dateArrived!.month}/${_dateArrived!.year}'
              : 'Not set'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateArrived ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _dateArrived = date);
            }
          },
        ),
      ],
    );
  }
}
