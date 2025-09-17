import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';
import 'adoption_form_screen.dart';

class PetAdoptionScreen extends StatefulWidget {
  const PetAdoptionScreen({super.key});

  @override
  State<PetAdoptionScreen> createState() => _PetAdoptionScreenState();
}

class _PetAdoptionScreenState extends State<PetAdoptionScreen> {
  List<PetListingModel> _petListings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PetListingType? _selectedType;
  PetListingStatus _selectedStatus = PetListingStatus.available;

  @override
  void initState() {
    super.initState();
    _loadPetListings();
  }

  Future<void> _loadPetListings() async {
    setState(() => _isLoading = true);
    try {
      final petListingService = Provider.of<PetListingService>(context, listen: false);
      final petListings = await petListingService.searchPetListings(
        query: _searchQuery,
        type: _selectedType,
        status: _selectedStatus,
      );
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopt a Pet'),
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
                    hintText: 'Search for pets...',
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
                          labelText: 'Pet Type',
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
                              'No pets available for adoption',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Check back later for new listings',
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
    );
  }

  Widget _buildPetListingCard(PetListingModel petListing) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _viewPetDetails(petListing),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pet Image
                  Container(
                    width: 100,
                    height: 100,
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
                            fontSize: 20,
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
                            if (petListing.isVaccinated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Vaccinated',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (petListing.isSpayedNeutered) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Spayed/Neutered',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Adopt Button
                  if (petListing.status == PetListingStatus.available)
                    ElevatedButton.icon(
                      onPressed: () => _startAdoptionProcess(petListing),
                      icon: const Icon(Icons.favorite, size: 16),
                      label: const Text('Adopt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              if (petListing.description != null && petListing.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  petListing.description!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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

  void _viewPetDetails(PetListingModel petListing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petListing.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${petListing.typeDisplayName} • ${petListing.breed}'),
                Text('${petListing.ageString} • ${petListing.gender.toString().split('.').last}'),
                if (petListing.weight != null) Text('Weight: ${petListing.weight} kg'),
                if (petListing.color != null) Text('Color: ${petListing.color}'),
                const SizedBox(height: 12),
                if (petListing.description != null) ...[
                  const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(petListing.description!),
                  const SizedBox(height: 12),
                ],
                if (petListing.specialNeeds != null) ...[
                  const Text('Special Needs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(petListing.specialNeeds!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    if (petListing.isVaccinated)
                      const Chip(label: Text('Vaccinated'), backgroundColor: Colors.green),
                    if (petListing.isSpayedNeutered)
                      const Chip(label: Text('Spayed/Neutered'), backgroundColor: Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    if (petListing.status == PetListingStatus.available) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startAdoptionProcess(petListing);
                        },
                        child: const Text('Adopt'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startAdoptionProcess(PetListingModel petListing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdoptionFormScreen(petListing: petListing),
      ),
    );
  }
}
