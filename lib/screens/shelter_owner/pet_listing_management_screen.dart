import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';
import '../../widgets/universal_image_widget.dart';
import '../../utils/pet_listing_image_helper.dart';
import '../../utils/fix_pet_listing_images.dart';
import 'add_edit_pet_listing_screen.dart';

class PetListingManagementScreen extends StatefulWidget {
  const PetListingManagementScreen({super.key});

  @override
  State<PetListingManagementScreen> createState() => _PetListingManagementScreenState();
}

class _PetListingManagementScreenState extends State<PetListingManagementScreen> {
  late String _shelterOwnerId;
  List<PetListingModel> _petListings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PetListingStatus? _selectedStatus;
  PetListingType? _selectedType;

  // Custom Color Scheme
  static const Color primaryBrown = Color(0xFF7d4d20);
  static const Color lightBeige = Color.fromARGB(255, 248, 248, 247);
  static const Color darkBrown = Color(0xFF5c3a18);
  static const Color mediumBeige = Color.fromARGB(255, 255, 251, 251);

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _shelterOwnerId = authService.currentUserModel?.id ?? '';
    _loadPetListings();
  }

  Future<void> _loadPetListings() async {
    setState(() => _isLoading = true);
    try {
      final petListingService = Provider.of<PetListingService>(context, listen: false);
      final petListings = await petListingService.getPetListingsByShelterOwnerId(_shelterOwnerId);
      setState(() {
        _petListings = petListings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading pet listings: $e');
    }
  }

  Future<void> _addTestImagesToPetListings() async {
    try {
      setState(() => _isLoading = true);
      
      for (final petListing in _petListings) {
        final base64Image = PetListingImageHelper.createColoredBase64Image('pet_${petListing.name}');
        await PetListingImageHelper.addBase64ImageToPetListing(petListing.id, base64Image);
        print('Added base64 image to pet listing: ${petListing.name}');
      }
      
      // Reload the pet listings to show the new images
      await _loadPetListings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added test images to ${_petListings.length} pet listings'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding test images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding test images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fixAllPetListingImages() async {
    try {
      setState(() => _isLoading = true);
      
      await FixPetListingImages.addImagesToAllPetListings();
      
      // Reload the pet listings to show the new images
      await _loadPetListings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fixed images for all pet listings'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error fixing pet listing images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPetListings() async {
    setState(() => _isLoading = true);
    try {
      final petListingService = Provider.of<PetListingService>(context, listen: false);
      final petListings = await petListingService.searchPetListings(
        query: _searchQuery,
        shelterOwnerId: _shelterOwnerId,
        type: _selectedType,
        status: _selectedStatus,
      );
      setState(() {
        _petListings = petListings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error searching pet listings: $e');
    }
  }

  Future<void> _deletePetListing(String listingId) async {
    try {
      final petListingService = Provider.of<PetListingService>(context, listen: false);
      final success = await petListingService.deletePetListing(listingId);
      if (success) {
        _loadPetListings();
        _showSuccessSnackBar('Pet listing deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete pet listing');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting pet listing: $e');
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
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: const Text(
          'Pet Listings Management',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: primaryBrown,
        foregroundColor: lightBeige,
        elevation: 0,
        actions: [
          // Debug button for fixing images
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.bug_report_rounded),
              onPressed: _fixAllPetListingImages,
              color: Colors.white,
            ),
          ),
          // Refresh button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: darkBrown,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadPetListings,
              color: lightBeige,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: mediumBeige,
              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrown.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search pet listings...',
                      hintStyle: TextStyle(color: primaryBrown.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search_rounded, color: primaryBrown),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: primaryBrown),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _loadPetListings();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBrown, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: lightBeige,
                    ),
                    style: const TextStyle(color: primaryBrown),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      if (value.isEmpty) {
                        _loadPetListings();
                      } else {
                        _searchPetListings();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: primaryBrown.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<PetListingType?>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            labelStyle: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBrown, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                            ),
                            filled: true,
                            fillColor: lightBeige,
                          ),
                          dropdownColor: lightBeige,
                          style: const TextStyle(color: primaryBrown),
                          items: [
                            const DropdownMenuItem<PetListingType?>(
                              value: null,
                              child: Text('All Types'),
                            ),
                            ...PetListingType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedType = value);
                            _searchPetListings();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: primaryBrown.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<PetListingStatus?>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBrown, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBrown.withOpacity(0.3)),
                            ),
                            filled: true,
                            fillColor: lightBeige,
                          ),
                          dropdownColor: lightBeige,
                          style: const TextStyle(color: primaryBrown),
                          items: [
                            const DropdownMenuItem<PetListingStatus?>(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            ...PetListingStatus.values.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toString().split('.').last),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value);
                            _searchPetListings();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pet Listings List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryBrown),
                      strokeWidth: 3,
                    ),
                  )
                : _petListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets_rounded, size: 80, color: primaryBrown.withOpacity(0.5)),
                            const SizedBox(height: 24),
                            Text(
                              'No pet listings found',
                              style: TextStyle(
                                fontSize: 22,
                                color: primaryBrown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first pet listing to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: primaryBrown.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: _petListings.length,
                        itemBuilder: (context, index) {
                          final petListing = _petListings[index];
                          return _buildPetListingCard(petListing);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add Test Images Button
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _addTestImagesToPetListings,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.image_rounded, color: Colors.white, size: 24),
            ),
          ),
          // Add New Pet Listing Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBrown, darkBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditPetListingScreen(),
                  ),
                );
                if (result == true) {
                  _loadPetListings();
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add_rounded, color: lightBeige, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetListingCard(PetListingModel petListing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: lightBeige,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pet Image
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: mediumBeige,
                    border: Border.all(color: primaryBrown.withOpacity(0.2), width: 1),
                  ),
                  child: petListing.photoUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: PetImageWidget(
                            imageUrl: petListing.photoUrls.first,
                            width: 85,
                            height: 85,
                          ),
                        )
                      : Icon(
                          Icons.pets_rounded,
                          size: 45,
                          color: primaryBrown.withOpacity(0.6),
                        ),
                ),
                const SizedBox(width: 16),
                // Pet Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petListing.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${petListing.typeDisplayName} • ${petListing.breed}',
                        style: TextStyle(
                          color: primaryBrown.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${petListing.ageString} • ${petListing.gender.toString().split('.').last}',
                        style: TextStyle(
                          color: primaryBrown.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(petListing.status).withOpacity(0.2),
                                  _getStatusColor(petListing.status).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _getStatusColor(petListing.status).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              petListing.statusDisplayName,
                              style: TextStyle(
                                color: _getStatusColor(petListing.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Container(
                  decoration: BoxDecoration(
                    color: mediumBeige,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryBrown.withOpacity(0.2)),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: primaryBrown),
                    color: lightBeige,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editPetListing(petListing);
                          break;
                        case 'delete':
                          _showDeleteDialog(petListing);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20, color: primaryBrown),
                            const SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: primaryBrown, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (petListing.description != null && petListing.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mediumBeige.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryBrown.withOpacity(0.1)),
                ),
                child: Text(
                  petListing.description!,
                  style: TextStyle(
                    color: primaryBrown.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PetListingStatus status) {
    switch (status) {
      case PetListingStatus.available:
        return Colors.green.shade600;
      case PetListingStatus.adopted:
        return Colors.blue.shade600;
      case PetListingStatus.pending:
        return Colors.orange.shade600;
      case PetListingStatus.unavailable:
        return Colors.red.shade600;
    }
  }

  void _editPetListing(PetListingModel petListing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetListingScreen(petListing: petListing),
      ),
    );
    if (result == true) {
      _loadPetListings();
    }
  }

  void _showDeleteDialog(PetListingModel petListing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: lightBeige,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Pet Listing',
            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${petListing.name}?',
            style: TextStyle(color: primaryBrown.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: primaryBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePetListing(petListing.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}