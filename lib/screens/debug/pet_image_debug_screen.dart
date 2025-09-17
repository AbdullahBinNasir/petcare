import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../utils/pet_image_helper.dart';
import '../../theme/pet_care_theme.dart';

class PetImageDebugScreen extends StatefulWidget {
  const PetImageDebugScreen({super.key});

  @override
  State<PetImageDebugScreen> createState() => _PetImageDebugScreenState();
}

class _PetImageDebugScreenState extends State<PetImageDebugScreen> {
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      
      if (authService.currentUserModel != null) {
        final pets = await petService.getPetsByOwnerId(authService.currentUserModel!.id);
        
        setState(() {
          _pets = pets.map((pet) => {
            'id': pet.id,
            'name': pet.name,
            'breed': pet.breed,
            'photoUrls': pet.photoUrls,
            'hasBase64Image': pet.photoUrls.isNotEmpty && pet.photoUrls.first.startsWith('data:image/'),
            'hasNetworkImage': pet.photoUrls.isNotEmpty && (pet.photoUrls.first.startsWith('http://') || pet.photoUrls.first.startsWith('https://')),
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBase64ImageToPet(String petId) async {
    try {
      final base64Image = PetImageHelper.createColoredBase64Image('test');
      await PetImageHelper.addBase64ImageToPet(petId, base64Image);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base64 image added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadPets(); // Reload to show changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addBase64ImagesToAllPets() async {
    try {
      for (final pet in _pets) {
        final base64Image = PetImageHelper.createColoredBase64Image('all_pets');
        await PetImageHelper.addBase64ImageToPet(pet['id'], base64Image);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base64 images added to all pets!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadPets(); // Reload to show changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Image Debug'),
        backgroundColor: PetCareTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(
                  child: Text(
                    'No pets found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addBase64ImagesToAllPets,
                              icon: const Icon(Icons.image),
                              label: const Text('Add Images to All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PetCareTheme.primaryBrown,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadPets,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PetCareTheme.lightBrown,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Pets list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pets.length,
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: pet['hasBase64Image'] 
                                    ? Colors.green 
                                    : pet['hasNetworkImage'] 
                                        ? Colors.blue 
                                        : Colors.grey,
                                child: Icon(
                                  pet['hasBase64Image'] 
                                      ? Icons.check 
                                      : pet['hasNetworkImage'] 
                                          ? Icons.link 
                                          : Icons.image_not_supported,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(pet['name']),
                              subtitle: Text(pet['breed']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Photos: ${pet['photoUrls'].length}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _addBase64ImageToPet(pet['id']),
                                    icon: const Icon(Icons.add_photo_alternate),
                                    tooltip: 'Add Base64 Image',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
