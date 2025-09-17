import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/pet_model.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../utils/image_utils.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  PetSpecies _selectedSpecies = PetSpecies.dog;
  PetGender _selectedGender = PetGender.male;
  HealthStatus _selectedHealthStatus = HealthStatus.healthy;
  DateTime? _dateOfBirth;
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Pet'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePet,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
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
              // Photo Section
              Text(
                'Pet Photos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Photo Button
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Selected Images
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      
                      return Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(left: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      image.path,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(image.path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
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
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PetSpecies>(
                      initialValue: _selectedSpecies,
                      decoration: const InputDecoration(
                        labelText: 'Species',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: PetSpecies.values.map((species) {
                        return DropdownMenuItem(
                          value: species,
                          child: Text(_getSpeciesName(species)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSpecies = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<PetGender>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(),
                      ),
                      items: PetGender.values.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(_getGenderName(gender)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: _selectDateOfBirth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select date of birth',
                    style: _dateOfBirth != null
                        ? null
                        : TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.palette),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Health Information
              Text(
                'Health Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<HealthStatus>(
                initialValue: _selectedHealthStatus,
                decoration: const InputDecoration(
                  labelText: 'Health Status',
                  prefixIcon: Icon(Icons.health_and_safety),
                  border: OutlineInputBorder(),
                ),
                items: HealthStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getHealthStatusName(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedHealthStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _microchipController,
                decoration: const InputDecoration(
                  labelText: 'Microchip ID (Optional)',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicalNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Medical Notes (Optional)',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Add Pet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        if (kIsWeb) {
          // For web, we need to create a File from the XFile
          _selectedImages.add(File(image.path));
        } else {
          // For mobile, we can use the path directly
          _selectedImages.add(File(image.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final petService = Provider.of<PetService>(context, listen: false);

        // Convert images to base64 using the new method
        List<String> photoUrls = [];
        for (File image in _selectedImages) {
          try {
            // Convert File to XFile for base64 conversion
            final xFile = XFile(image.path);
            final base64DataUrl = await petService.uploadPetPhotoFromXFile(xFile, DateTime.now().millisecondsSinceEpoch.toString());
            if (base64DataUrl != null && base64DataUrl.isNotEmpty) {
              photoUrls.add(base64DataUrl);
              print('✅ Converted image to base64: ${base64DataUrl.substring(0, 50)}...');
            }
          } catch (e) {
            print('❌ Error converting image to base64: $e');
            // Fallback to Firebase Storage upload
            final url = await petService.uploadPetPhoto(image, DateTime.now().millisecondsSinceEpoch.toString());
            if (url != null) {
              photoUrls.add(url);
            }
          }
        }

        print('📸 Total photo URLs prepared: ${photoUrls.length}');

        // Create pet model
        final pet = PetModel(
          id: '', // Will be set by Firestore
          ownerId: authService.currentUser!.uid,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          gender: _selectedGender,
          dateOfBirth: _dateOfBirth,
          weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
          color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
          microchipId: _microchipController.text.trim().isNotEmpty ? _microchipController.text.trim() : null,
          photoUrls: photoUrls,
          healthStatus: _selectedHealthStatus,
          medicalNotes: _medicalNotesController.text.trim().isNotEmpty ? _medicalNotesController.text.trim() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('🐕 Creating pet: ${pet.name} with ${pet.photoUrls.length} photos');

        final petId = await petService.addPet(pet);

        if (petId != null) {
          print('✅ Pet created successfully with ID: $petId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to add pet');
        }
      } catch (e) {
        print('❌ Error saving pet: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSpeciesName(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return 'Dog';
      case PetSpecies.cat:
        return 'Cat';
      case PetSpecies.bird:
        return 'Bird';
      case PetSpecies.rabbit:
        return 'Rabbit';
      case PetSpecies.hamster:
        return 'Hamster';
      case PetSpecies.fish:
        return 'Fish';
      case PetSpecies.reptile:
        return 'Reptile';
      case PetSpecies.other:
        return 'Other';
    }
  }

  String _getGenderName(PetGender gender) {
    switch (gender) {
      case PetGender.male:
        return 'Male';
      case PetGender.female:
        return 'Female';
      case PetGender.unknown:
        return 'Unknown';
    }
  }

  String _getHealthStatusName(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.sick:
        return 'Sick';
      case HealthStatus.recovering:
        return 'Recovering';
      case HealthStatus.critical:
        return 'Critical';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }
}
