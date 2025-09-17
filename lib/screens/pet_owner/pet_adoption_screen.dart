import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_listing_service.dart';
import '../../models/pet_listing_model.dart';
import '../../theme/pet_care_theme.dart';
import '../../widgets/universal_image_widget.dart';
import '../../utils/pet_listing_image_helper.dart';
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
        onPressed: _addTestImagesToPetListings,
        backgroundColor: PetCareTheme.primaryBrown,
        child: const Icon(Icons.image, color: Colors.white),
        tooltip: 'Add Test Images to Pet Listings',
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
                        : _petListings.isEmpty
                            ? _buildEmptyState()
                            : _buildPetListingsList(),
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
                  'Adopt a Pet',
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
                onPressed: () => _loadPetListings(),
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
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for pets...',
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
                        _loadPetListings();
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
                _loadPetListings();
              } else {
                _searchPetListings();
              }
            },
          ),
          const SizedBox(height: 16),
          // Filter Row
          DropdownButtonFormField<PetListingType?>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Pet Type',
              labelStyle: TextStyle(
                color: PetCareTheme.primaryBrown,
                fontWeight: FontWeight.w600,
              ),
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
            dropdownColor: PetCareTheme.cardWhite,
            style: TextStyle(
              color: PetCareTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
            items: [
              DropdownMenuItem<PetListingType?>(
                value: null,
                child: Text(
                  'All Types',
                  style: TextStyle(color: PetCareTheme.textDark),
                ),
              ),
              ...PetListingType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(
                  type.toString().split('.').last,
                  style: TextStyle(color: PetCareTheme.textDark),
                ),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value);
              _searchPetListings();
            },
          ),
        ],
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
              'Loading Pet Listings...',
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
                Icons.pets_rounded,
                size: 50,
                color: PetCareTheme.primaryBrown.withOpacity( 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pets Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new adoption listings',
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

  Widget _buildPetListingsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _petListings.length,
      itemBuilder: (context, index) {
        final petListing = _petListings[index];
        return _buildPetListingCard(petListing);
      },
    );
  }

  Widget _buildPetListingCard(PetListingModel petListing) {
    final statusColor = _getStatusColor(petListing.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity( 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: statusColor.withOpacity( 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewPetDetails(petListing),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          PetCareTheme.primaryBeige.withOpacity( 0.1),
                          PetCareTheme.lightBrown.withOpacity( 0.1),
                        ],
                      ),
                    ),
                    child: petListing.photoUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PetImageWidget(
                              imageUrl: petListing.photoUrls.first,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Icon(
                            Icons.pets_rounded,
                            size: 40,
                            color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                          ),
                  ),
                  const SizedBox(width: 20),
                  // Pet Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petListing.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: PetCareTheme.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${petListing.typeDisplayName} • ${petListing.breed}',
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${petListing.ageString} • ${petListing.gender.toString().split('.').last}',
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity( 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withOpacity( 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                petListing.statusDisplayName,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (petListing.isVaccinated) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PetCareTheme.softGreen.withOpacity( 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: PetCareTheme.softGreen.withOpacity( 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Vaccinated',
                                  style: TextStyle(
                                    color: PetCareTheme.softGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                            if (petListing.isSpayedNeutered) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PetCareTheme.accentGold.withOpacity( 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: PetCareTheme.accentGold.withOpacity( 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Spayed/Neutered',
                                  style: TextStyle(
                                    color: PetCareTheme.accentGold,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
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
                      child: ElevatedButton.icon(
                        onPressed: () => _startAdoptionProcess(petListing),
                        icon: const Icon(Icons.favorite_rounded, size: 16),
                        label: const Text('Adopt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (petListing.description != null && petListing.description!.isNotEmpty) ...[
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
                          petListing.description!,
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
        return PetCareTheme.softGreen;
      case PetListingStatus.adopted:
        return PetCareTheme.accentGold;
      case PetListingStatus.pending:
        return PetCareTheme.warmRed;
      case PetListingStatus.unavailable:
        return PetCareTheme.darkBrown;
    }
  }

  void _viewPetDetails(PetListingModel petListing) {
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            PetCareTheme.primaryBeige.withOpacity( 0.1),
                            PetCareTheme.lightBrown.withOpacity( 0.1),
                          ],
                        ),
                      ),
                      child: petListing.photoUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: PetImageWidget(
                                imageUrl: petListing.photoUrls.first,
                                width: 60,
                                height: 60,
                              ),
                            )
                          : Icon(
                              Icons.pets_rounded,
                              size: 30,
                              color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petListing.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: PetCareTheme.textDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${petListing.typeDisplayName} • ${petListing.breed}',
                            style: TextStyle(
                              color: PetCareTheme.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Pet Details
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
                        'Pet Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PetCareTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('${petListing.ageString} • ${petListing.gender.toString().split('.').last}'),
                      if (petListing.weight != null) Text('Weight: ${petListing.weight} kg'),
                      if (petListing.color != null) Text('Color: ${petListing.color}'),
                    ],
                  ),
                ),
                
                if (petListing.description != null && petListing.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          petListing.description!,
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (petListing.specialNeeds != null && petListing.specialNeeds!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PetCareTheme.warmPurple.withOpacity( 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PetCareTheme.warmPurple.withOpacity( 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Needs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          petListing.specialNeeds!,
                          style: TextStyle(
                            color: PetCareTheme.textLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (petListing.isVaccinated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PetCareTheme.softGreen.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PetCareTheme.softGreen.withOpacity( 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Vaccinated',
                          style: TextStyle(
                            color: PetCareTheme.softGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (petListing.isSpayedNeutered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PetCareTheme.accentGold.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PetCareTheme.accentGold.withOpacity( 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Spayed/Neutered',
                          style: TextStyle(
                            color: PetCareTheme.accentGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: PetCareTheme.textLight,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                    if (petListing.status == PetListingStatus.available) ...[
                      const SizedBox(width: 12),
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
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _startAdoptionProcess(petListing);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Adopt'),
                        ),
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

  Future<void> _addTestImagesToPetListings() async {
    try {
      if (_petListings.isNotEmpty) {
        for (int i = 0; i < _petListings.length; i++) {
          final petListing = _petListings[i];
          final base64Image = PetListingImageHelper.createColoredBase64Image('listing_$i');
          
          await PetListingImageHelper.addBase64ImageToPetListing(petListing.id, base64Image);
          print('✅ Added base64 image to pet listing ${i + 1}: ${petListing.name}');
        }
        
        // Reload data to show the new images
        _loadPetListings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base64 images added to all pet listings!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding base64 images to pet listings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
