import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../services/auth_service.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import '../../theme/pet_care_theme.dart';
import 'add_health_record_screen.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _vaccinationRecords = [];
  List<HealthRecordModel> _dewormingRecords = [];
  List<HealthRecordModel> _allergyRecords = [];
  List<HealthRecordModel> _upcomingReminders = [];
  Map<String, PetModel> _pets = {};
  PetModel? _selectedPet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);

      debugPrint('HealthTrackingScreen: Starting data load...');
      
      if (authService.currentUserModel == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final pets = await petService.getPetsByOwnerId(authService.currentUserModel!.id);
      debugPrint('HealthTrackingScreen: Found ${pets.length} pets');

      if (pets.isEmpty) {
        setState(() {
          _pets = {};
          _selectedPet = null;
          _isLoading = false;
        });
        return;
      }

      // Convert to map and select first pet
      final petsMap = <String, PetModel>{};
      for (final pet in pets) {
        petsMap[pet.id] = pet;
      }

      setState(() {
        _pets = petsMap;
        _selectedPet = pets.first;
      });

      // Load records for the selected pet
      await _loadRecordsForPet(pets.first.id);

    } catch (e) {
      debugPrint('HealthTrackingScreen: Error in _loadData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecordsForPet(String petId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      
      debugPrint('HealthTrackingScreen: Fetching records for pet: $petId');
      final allRecords = await healthService.getHealthRecordsByPetId(petId);
      debugPrint('HealthTrackingScreen: Retrieved ${allRecords.length} records');

      // Filter records
      final vaccinationRecords = allRecords.where((r) => r.type == HealthRecordType.vaccination).toList();
      final medicationRecords = allRecords.where((r) => r.type == HealthRecordType.medication).toList();
      final allergyRecords = allRecords.where((r) => r.type == HealthRecordType.allergy).toList();

      // Calculate upcoming reminders
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      final upcomingReminders = allRecords.where((record) => 
          record.nextDueDate != null && 
          record.nextDueDate!.isAfter(now) &&
          record.nextDueDate!.isBefore(thirtyDaysLater)).toList();

      setState(() {
        _allRecords = allRecords;
        _vaccinationRecords = vaccinationRecords;
        _dewormingRecords = medicationRecords; // Include all medications for now
        _allergyRecords = allergyRecords;
        _upcomingReminders = upcomingReminders;
        _isLoading = false;
      });

      debugPrint('HealthTrackingScreen: State updated with ${_allRecords.length} records');

    } catch (e) {
      debugPrint('HealthTrackingScreen: Error loading records: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load health records: $e'),
            backgroundColor: PetCareTheme.warmRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadRecordsForPet(petId),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: _isLoading
                  ? _buildLoadingState()
                  : Column(
                      children: [
                        // Pet Selector
                        if (_pets.isNotEmpty) _buildPetSelector(),
                        
                        // Content
                        Expanded(
                          child: _pets.isEmpty
                              ? _buildNoPetsView()
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildOverviewTab(),
                                    _buildRecordsList(_vaccinationRecords, 'No vaccination records'),
                                    _buildRecordsList(_dewormingRecords, 'No medication records'),
                                    _buildRecordsList(_allergyRecords, 'No allergy records'),
                                    _buildRecordsList(_upcomingReminders, 'No upcoming reminders'),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedPet != null ? _buildModernFAB() : null,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                      'Health Tracking',
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
                    onPressed: () => _loadData(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: PetCareTheme.primaryBeige.withOpacity( 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: PetCareTheme.primaryBeige,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: PetCareTheme.primaryBrown,
                unselectedLabelColor: PetCareTheme.primaryBeige.withOpacity( 0.7),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                tabs: [
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dashboard_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Overview (${_allRecords.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vaccines_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Vaccines (${_vaccinationRecords.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medication_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Medications (${_dewormingRecords.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Allergies (${_allergyRecords.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Reminders (${_upcomingReminders.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
              'Loading Health Records...',
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

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: PetCareTheme.accentGradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHealthRecordScreen(petId: _selectedPet!.id),
            ),
          );
          if (result == true && _selectedPet != null) {
            await _loadRecordsForPet(_selectedPet!.id);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'Add Record',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNoPetsView() {
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
              'No Pets Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please add a pet first to start tracking health records',
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

  Widget _buildPetSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PetCareTheme.elevatedShadow],
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity( 0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<PetModel>(
        value: _selectedPet,
        decoration: InputDecoration(
          labelText: 'Select Pet',
          labelStyle: TextStyle(
            color: PetCareTheme.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.pets_rounded,
            color: PetCareTheme.primaryBrown,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity( 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
        items: _pets.values.map((pet) {
          return DropdownMenuItem(
            value: pet,
            child: Text(
              '${pet.name} - ${pet.breed}',
              style: TextStyle(
                color: PetCareTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (pet) async {
          if (pet != null) {
            setState(() {
              _selectedPet = pet;
              _allRecords = [];
              _vaccinationRecords = [];
              _dewormingRecords = [];
              _allergyRecords = [];
              _upcomingReminders = [];
            });
            await _loadRecordsForPet(pet.id);
          }
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: PetCareTheme.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Records', _allRecords.length.toString(), PetCareTheme.accentGold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Vaccinations', _vaccinationRecords.length.toString(), PetCareTheme.softGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Medications', _dewormingRecords.length.toString(), PetCareTheme.warmRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Allergies', _allergyRecords.length.toString(), PetCareTheme.warmPurple),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'All Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: PetCareTheme.textDark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_allRecords.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [PetCareTheme.elevatedShadow],
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                        Icons.medical_services_rounded,
                        size: 40,
                        color: PetCareTheme.primaryBrown.withOpacity( 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Health Records Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: PetCareTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first health record to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: PetCareTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ..._allRecords.map((record) => _buildRecordCard(record)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity( 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withOpacity( 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PetCareTheme.textLight,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<HealthRecordModel> records, String emptyMessage) {
    if (records.isEmpty) {
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PetCareTheme.lightBrown.withOpacity( 0.1),
                      PetCareTheme.warmPurple.withOpacity( 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 40,
                  color: PetCareTheme.lightBrown.withOpacity( 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PetCareTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No records found in this category',
                style: TextStyle(
                  fontSize: 14,
                  color: PetCareTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(records[index]);
      },
    );
  }

  Widget _buildRecordCard(HealthRecordModel record) {
    final typeColor = _getRecordTypeColor(record.type);
    final typeIcon = _getRecordTypeIcon(record.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeColor.withOpacity( 0.2),
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
            color: typeColor.withOpacity( 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title and type
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        typeColor.withOpacity( 0.1),
                        typeColor.withOpacity( 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PetCareTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRecordTypeName(record.type),
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: typeColor.withOpacity( 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRecordTypeName(record.type),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Description if available
            if (record.description.isNotEmpty) ...[
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
                        record.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Date and time info
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
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: PetCareTheme.primaryBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${_formatDate(record.recordDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PetCareTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (record.nextDueDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: PetCareTheme.primaryBrown,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Next Due: ${_formatDate(record.nextDueDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PetCareTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Notes if available
            if (record.notes != null && record.notes!.isNotEmpty) ...[
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_rounded,
                      size: 18,
                      color: PetCareTheme.warmPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notes: ${record.notes!}',
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          height: 1.4,
                        ),
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

  Color _getRecordTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return PetCareTheme.softGreen;
      case HealthRecordType.medication:
        return PetCareTheme.warmRed;
      case HealthRecordType.allergy:
        return PetCareTheme.warmRed.withOpacity( 0.8);
      case HealthRecordType.checkup:
        return PetCareTheme.accentGold;
      case HealthRecordType.surgery:
        return PetCareTheme.warmPurple;
      case HealthRecordType.injury:
        return PetCareTheme.darkBrown;
      case HealthRecordType.other:
        return PetCareTheme.lightBrown;
    }
  }

  IconData _getRecordTypeIcon(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Icons.vaccines_rounded;
      case HealthRecordType.medication:
        return Icons.medication_rounded;
      case HealthRecordType.allergy:
        return Icons.warning_rounded;
      case HealthRecordType.checkup:
        return Icons.medical_services_rounded;
      case HealthRecordType.surgery:
        return Icons.healing_rounded;
      case HealthRecordType.injury:
        return Icons.emergency_rounded;
      case HealthRecordType.other:
        return Icons.medical_information_rounded;
    }
  }

  String _getRecordTypeName(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.allergy:
        return 'Allergy';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.injury:
        return 'Injury';
      case HealthRecordType.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
