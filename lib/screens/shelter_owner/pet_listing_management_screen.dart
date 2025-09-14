import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';
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
        title: const Text('Pet Listings Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPetListings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pet listings...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _loadPetListings();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    if (value.isEmpty) {
                      _loadPetListings();
                    } else {
                      _searchPetListings();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PetListingType?>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<PetListingStatus?>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
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
                  ],
                ),
              ],
            ),
          ),
          // Pet Listings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _petListings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No pet listings found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Add your first pet listing to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _petListings.length,
                        itemBuilder: (context, index) {
                          final petListing = _petListings[index];
                          return _buildPetListingCard(petListing);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPetListingCard(PetListingModel petListing) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pet Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: petListing.photoUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            petListing.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.pets,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.pets,
                          size: 40,
                          color: Colors.grey,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${petListing.typeDisplayName} • ${petListing.breed}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${petListing.ageString} • ${petListing.gender.toString().split('.').last}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(petListing.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              petListing.statusDisplayName,
                              style: TextStyle(
                                color: _getStatusColor(petListing.status),
                                fontWeight: FontWeight.w500,
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
                PopupMenuButton<String>(
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (petListing.description != null && petListing.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                petListing.description!,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        return Colors.green;
      case PetListingStatus.adopted:
        return Colors.blue;
      case PetListingStatus.pending:
        return Colors.orange;
      case PetListingStatus.unavailable:
        return Colors.red;
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
          title: const Text('Delete Pet Listing'),
          content: Text('Are you sure you want to delete ${petListing.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePetListing(petListing.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
