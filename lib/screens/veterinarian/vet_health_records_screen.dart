import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../shared/add_health_record_screen.dart';

class VetHealthRecordsTheme {
  // Enhanced color scheme with your specified colors
  static const Color primaryBeige = Color.fromARGB(255, 255, 255, 255);
  static const Color primaryBrown = Color(0xFF7D4D20); // Your brown color #7d4d20
  static const Color lightBrown = Color(0xFF9B6B3A); // Lighter shade of your brown
  static const Color darkBrown = Color(0xFF5A3417); // Darker shade for depth
  static const Color accentGold = Color(0xFFD4AF37); // Gold accent
  static const Color softGreen = Color(0xFF8FBC8F); // Soft green
  static const Color warmRed = Color(0xFFCD853F); // Warm red-brown
  static const Color warmPurple = Color(0xFFBC9A6A); // Warm taupe
  static const Color cardWhite = Color(0xFFFFFDF7); // Warm white for cards
  static const Color shadowColor = Color(0x1A7D4D20); // Subtle shadow
  
  // Gradients
  static const List<Color> primaryGradient = [
    primaryBrown,
    lightBrown,
  ];
  
  static const List<Color> accentGradient = [
    accentGold,
    lightBrown,
  ];
  
  // Background gradient
  static const List<Color> backgroundGradient = [
    Color(0xFFFFFDF7),
    Color(0xFFF8F6F0),
  ];
}

class VetHealthRecordsScreen extends StatefulWidget {
  const VetHealthRecordsScreen({super.key});

  @override
  State<VetHealthRecordsScreen> createState() => _VetHealthRecordsScreenState();
}

class _VetHealthRecordsScreenState extends State<VetHealthRecordsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _animationsInitialized = false;
  
  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _recentRecords = [];
  List<HealthRecordModel> _dueRecords = [];
  List<HealthRecordModel> _overdueRecords = [];
  Map<String, PetModel> _pets = {};
  PetModel? _selectedPet;
  bool _isLoading = true;
  String _searchQuery = '';
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize animation controllers
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Mark animations as initialized
    _animationsInitialized = true;
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🏥 VetHealthRecordsScreen: Starting to load data...');
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      if (authService.currentUser == null) {
        print('❌ VetHealthRecordsScreen: No current user found');
        return;
      }

      print('👤 VetHealthRecordsScreen: Current user: ${authService.currentUser!.uid}');
      print('👤 VetHealthRecordsScreen: User email: ${authService.currentUser!.email}');
      
      // First, let's try to get ALL health records to see what's in the database
      print('🔍 VetHealthRecordsScreen: Fetching ALL health records for debugging...');
      final allRecords = await healthService.getAllHealthRecords();
      print('📊 VetHealthRecordsScreen: Found ${allRecords.length} total health records in database');
      
      if (allRecords.isNotEmpty) {
        print('📋 VetHealthRecordsScreen: Sample records:');
        for (int i = 0; i < allRecords.take(3).length; i++) {
          final record = allRecords[i];
          print('  Record ${i + 1}:');
          print('    ID: ${record.id}');
          print('    Title: ${record.title}');
          print('    Pet ID: ${record.petId}');
          print('    Vet ID: ${record.veterinarianId}');
          print('    Type: ${record.type}');
          print('    Date: ${record.recordDate}');
        }
      }
      
      // Load all health records created by this veterinarian
      print('🏥 VetHealthRecordsScreen: Loading health records for vet ID: ${authService.currentUser!.uid}');
      final records = await healthService.getHealthRecordsByVetId(authService.currentUser!.uid);
      print('📊 VetHealthRecordsScreen: Received ${records.length} health records from service');
      
      if (records.isNotEmpty) {
        print('📋 VetHealthRecordsScreen: Vet records details:');
        for (int i = 0; i < records.take(3).length; i++) {
          final record = records[i];
          print('  Vet Record ${i + 1}:');
          print('    ID: ${record.id}');
          print('    Title: ${record.title}');
          print('    Pet ID: ${record.petId}');
          print('    Vet ID: ${record.veterinarianId}');
        }
      } else {
        print('⚠️ VetHealthRecordsScreen: No records found for this vet. Checking if vet ID matches...');
        final vetRecords = allRecords.where((r) => r.veterinarianId == authService.currentUser!.uid).toList();
        print('🔍 VetHealthRecordsScreen: Found ${vetRecords.length} records with matching vet ID in all records');
      }
      
      // Load pets from appointments (pets assigned to this veterinarian)
      print('🐕 VetHealthRecordsScreen: Loading appointments for vet...');
      final appointments = await appointmentService.getAppointmentsByVeterinarian(authService.currentUser!.uid);
      print('📅 VetHealthRecordsScreen: Found ${appointments.length} appointments');
      final appointmentPetIds = appointments.map((a) => a.petId).toSet();
      print('🐕 VetHealthRecordsScreen: Pet IDs from appointments: ${appointmentPetIds.toList()}');
      
      // Also include pets from existing health records
      final recordPetIds = records.map((r) => r.petId).toSet();
      print('🐕 VetHealthRecordsScreen: Pet IDs from health records: ${recordPetIds.toList()}');
      final allPetIds = {...appointmentPetIds, ...recordPetIds};
      print('🐕 VetHealthRecordsScreen: All unique pet IDs: ${allPetIds.toList()}');
      
      final pets = <String, PetModel>{};
      
      print('🐕 VetHealthRecordsScreen: Loading pet details...');
      for (final petId in allPetIds) {
        print('🔍 VetHealthRecordsScreen: Loading pet: $petId');
        final pet = await petService.getPetById(petId);
        if (pet != null) {
          pets[petId] = pet;
          print('✅ VetHealthRecordsScreen: Loaded pet: ${pet.name} (${pet.species})');
        } else {
          print('❌ VetHealthRecordsScreen: Failed to load pet: $petId');
        }
      }

      print('📊 VetHealthRecordsScreen: Before setState:');
      print('  - Records: ${records.length}');
      print('  - Pets: ${pets.length}');
      print('  - Pet names: ${pets.values.map((p) => p.name).toList()}');

      setState(() {
        _allRecords = records;
        _pets = pets;
        _recentRecords = records.take(10).toList();
        _dueRecords = records.where((r) => r.isDue).toList();
        _overdueRecords = records.where((r) => r.isOverdue).toList();
        _isLoading = false;
      });
      
      // Start animations after data is loaded
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
      _scaleAnimationController.forward();
      
      print('✅ VetHealthRecordsScreen: Data loaded successfully');
      print('📊 VetHealthRecordsScreen: Final counts:');
      print('  - All records: ${_allRecords.length}');
      print('  - Recent records: ${_recentRecords.length}');
      print('  - Due records: ${_dueRecords.length}');
      print('  - Overdue records: ${_overdueRecords.length}');
      print('  - Pets loaded: ${_pets.length}');
      print('  - Pet details: ${_pets.entries.map((e) => '${e.key}: ${e.value.name}').toList()}');
    } catch (e) {
      print('❌ VetHealthRecordsScreen: Error loading health records: $e');
      print('❌ VetHealthRecordsScreen: Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ VetHealthRecordsScreen: Firebase error code: ${e.code}');
        print('❌ VetHealthRecordsScreen: Firebase error message: ${e.message}');
      }
      debugPrint('Error loading health records: $e');
      setState(() => _isLoading = false);
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
            colors: VetHealthRecordsTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: VetHealthRecordsTheme.primaryGradient,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // AppBar content
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: VetHealthRecordsTheme.primaryBeige,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              'Health Records',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: VetHealthRecordsTheme.primaryBeige,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: VetHealthRecordsTheme.primaryBeige.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.search,
                                color: VetHealthRecordsTheme.primaryBeige,
                                size: 22,
                              ),
                              onPressed: _showSearchDialog,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: VetHealthRecordsTheme.primaryBeige.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.upload_file,
                                color: VetHealthRecordsTheme.primaryBeige,
                                size: 22,
                              ),
                              onPressed: _showUploadDialog,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: VetHealthRecordsTheme.primaryBeige.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: VetHealthRecordsTheme.primaryBeige,
                                size: 22,
                              ),
                              onPressed: _loadData,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom TabBar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: VetHealthRecordsTheme.primaryBeige.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: VetHealthRecordsTheme.primaryBeige.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: VetHealthRecordsTheme.primaryBeige,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: VetHealthRecordsTheme.primaryBrown,
                        unselectedLabelColor: VetHealthRecordsTheme.primaryBeige.withOpacity(0.8),
                        labelStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                        padding: const EdgeInsets.all(3),
                        isScrollable: false,
                        tabs: [
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list_alt_rounded, size: 14),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'All Records',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 14),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Recent',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_send_rounded, size: 14),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Due Soon',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_rounded, size: 14),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Overdue',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: VetHealthRecordsTheme.cardWhite.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(VetHealthRecordsTheme.primaryBrown),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading Health Records...',
                              style: TextStyle(
                                color: VetHealthRecordsTheme.primaryBrown,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecordsList(_allRecords, 'No health records found'),
                        _buildRecordsList(_recentRecords, 'No recent records'),
                        _buildRecordsList(_dueRecords, 'No records due soon'),
                        _buildRecordsList(_overdueRecords, 'No overdue records'),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _animationsInitialized 
          ? AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: VetHealthRecordsTheme.accentGradient,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: VetHealthRecordsTheme.shadowColor,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FloatingActionButton.extended(
                      onPressed: _showPetSelector,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      icon: Icon(
                        Icons.add,
                        color: VetHealthRecordsTheme.primaryBeige,
                      ),
                      label: Text(
                        'Add Record',
                        style: TextStyle(
                          color: VetHealthRecordsTheme.primaryBeige,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: VetHealthRecordsTheme.accentGradient,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: VetHealthRecordsTheme.shadowColor,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showPetSelector,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: Icon(
                  Icons.add,
                  color: VetHealthRecordsTheme.primaryBeige,
                ),
                label: Text(
                  'Add Record',
                  style: TextStyle(
                    color: VetHealthRecordsTheme.primaryBeige,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRecordsList(List<HealthRecordModel> records, String emptyMessage) {
    if (records.isEmpty) {
      if (!_animationsInitialized) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VetHealthRecordsTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: VetHealthRecordsTheme.shadowColor,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VetHealthRecordsTheme.lightBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: VetHealthRecordsTheme.lightBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VetHealthRecordsTheme.primaryBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      
      return AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: VetHealthRecordsTheme.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: VetHealthRecordsTheme.shadowColor,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VetHealthRecordsTheme.lightBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 48,
                            color: VetHealthRecordsTheme.lightBrown,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: VetHealthRecordsTheme.primaryBrown,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (!_animationsInitialized) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final pet = _pets[record.petId];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: VetHealthRecordsTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: VetHealthRecordsTheme.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showRecordDetails(record),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Leading Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getRecordTypeColor(record.type).withOpacity(0.2),
                              _getRecordTypeColor(record.type).withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getRecordTypeColor(record.type).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getRecordTypeIcon(record.type),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: VetHealthRecordsTheme.primaryBrown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (pet != null) ...[
                              Text(
                                'Pet: ${pet.name} (${pet.species.toString().split('.').last})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: VetHealthRecordsTheme.lightBrown,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              'Date: ${DateFormat('MMM dd, yyyy').format(record.recordDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: VetHealthRecordsTheme.lightBrown.withOpacity(0.8),
                              ),
                            ),
                            if (record.nextDueDate != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: record.isOverdue 
                                      ? VetHealthRecordsTheme.warmRed.withOpacity(0.2)
                                      : VetHealthRecordsTheme.accentGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Next Due: ${DateFormat('MMM dd, yyyy').format(record.nextDueDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: record.isOverdue 
                                        ? VetHealthRecordsTheme.warmRed
                                        : VetHealthRecordsTheme.accentGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Menu Button
                      Container(
                        decoration: BoxDecoration(
                          color: VetHealthRecordsTheme.lightBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) => _handleRecordAction(value, record),
                          icon: Icon(
                            Icons.more_vert,
                            color: VetHealthRecordsTheme.primaryBrown,
                            size: 20,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: VetHealthRecordsTheme.primaryBrown),
                                  const SizedBox(width: 8),
                                  Text('View Details', style: TextStyle(color: VetHealthRecordsTheme.primaryBrown)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: VetHealthRecordsTheme.accentGold),
                                  const SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: VetHealthRecordsTheme.accentGold)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: VetHealthRecordsTheme.warmRed),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: VetHealthRecordsTheme.warmRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final pet = _pets[record.petId];
                
                return AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: VetHealthRecordsTheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: VetHealthRecordsTheme.shadowColor,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showRecordDetails(record),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Leading Icon
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _getRecordTypeColor(record.type).withOpacity(0.2),
                                          _getRecordTypeColor(record.type).withOpacity(0.4),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getRecordTypeColor(record.type).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getRecordTypeIcon(record.type),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: VetHealthRecordsTheme.primaryBrown,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (pet != null) ...[
                                          Text(
                                            'Pet: ${pet.name} (${pet.species.toString().split('.').last})',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: VetHealthRecordsTheme.lightBrown,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                        ],
                                        Text(
                                          'Date: ${DateFormat('MMM dd, yyyy').format(record.recordDate)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: VetHealthRecordsTheme.lightBrown.withOpacity(0.8),
                                          ),
                                        ),
                                        if (record.nextDueDate != null) ...[
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: record.isOverdue 
                                                  ? VetHealthRecordsTheme.warmRed.withOpacity(0.2)
                                                  : VetHealthRecordsTheme.accentGold.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Next Due: ${DateFormat('MMM dd, yyyy').format(record.nextDueDate!)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: record.isOverdue 
                                                    ? VetHealthRecordsTheme.warmRed
                                                    : VetHealthRecordsTheme.accentGold,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Menu Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: VetHealthRecordsTheme.lightBrown.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: PopupMenuButton<String>(
                                      onSelected: (value) => _handleRecordAction(value, record),
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: VetHealthRecordsTheme.primaryBrown,
                                        size: 20,
                                      ),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility, color: VetHealthRecordsTheme.primaryBrown),
                                              const SizedBox(width: 8),
                                              Text('View Details', style: TextStyle(color: VetHealthRecordsTheme.primaryBrown)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: VetHealthRecordsTheme.accentGold),
                                              const SizedBox(width: 8),
                                              Text('Edit', style: TextStyle(color: VetHealthRecordsTheme.accentGold)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: VetHealthRecordsTheme.warmRed),
                                              const SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: VetHealthRecordsTheme.warmRed)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Health Records'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, pet name, or description...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _filterRecords();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _filterRecords() {
    if (_searchQuery.isEmpty) {
      _loadData();
      return;
    }

    final filteredRecords = _allRecords.where((record) {
      final pet = _pets[record.petId];
      return record.title.toLowerCase().contains(_searchQuery) ||
             record.description.toLowerCase().contains(_searchQuery) ||
             (pet?.name.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    setState(() {
      _allRecords = filteredRecords;
    });
  }

  void _showPetSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Pet for Health Record'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _pets.isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No pets found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pets will appear here once they have appointments with you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets.values.elementAt(index);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pet.photoUrls.isNotEmpty
                              ? NetworkImage(pet.photoUrls.first)
                              : null,
                          child: pet.photoUrls.isEmpty
                              ? Icon(_getPetSpeciesIcon(pet.species))
                              : null,
                        ),
                        title: Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${pet.species.toString().split('.').last} • ${pet.breed}'),
                            if (pet.dateOfBirth != null)
                              Text(
                                'Age: ${_calculateAge(pet.dateOfBirth!)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.add_circle, color: Colors.blue),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAddRecord(pet.id);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddRecord(String petId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthRecordScreen(petId: petId),
      ),
    ).then((_) => _loadData());
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Medical Files'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a pet to upload files for:'),
            const SizedBox(height: 16),
            if (_pets.isEmpty)
              const Column(
                children: [
                  Icon(Icons.pets, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No pets found. Create health records for pets with appointments.'),
                ],
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets.values.elementAt(index);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: pet.photoUrls.isNotEmpty
                            ? NetworkImage(pet.photoUrls.first)
                            : null,
                        child: pet.photoUrls.isEmpty
                            ? Icon(_getPetSpeciesIcon(pet.species))
                            : null,
                      ),
                      title: Text(pet.name),
                      subtitle: Text('${pet.species.toString().split('.').last} • ${pet.breed}'),
                      trailing: const Icon(Icons.upload_file),
                      onTap: () {
                        Navigator.pop(context);
                        _showFileUploadOptions(pet.id);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFileUploadOptions(String petId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Medical Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(petId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(petId, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument(petId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(String petId, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadToStorage(petId, File(image.path), 'image');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadDocument(String petId) async {
    // For document upload, we'll use a simple file picker simulation
    // In a real app, you'd use file_picker package
    _showErrorSnackBar('Document upload feature coming soon');
  }

  Future<void> _uploadToStorage(String petId, File file, String type) async {
    try {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('medical_files/$petId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create a health record for the uploaded file
      final healthRecord = HealthRecordModel(
        id: '', // Will be set by Firestore
        petId: petId,
        veterinarianId: authService.currentUser!.uid,
        type: HealthRecordType.other,
        title: 'Uploaded $type - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
        description: 'Medical file uploaded by veterinarian',
        recordDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachmentUrls: [downloadUrl],
      );

      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      await healthService.addHealthRecord(healthRecord);

      _showSuccessSnackBar('File uploaded successfully');
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Error uploading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRecordDetails(HealthRecordModel record) {
    final pet = _pets[record.petId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pet != null) ...[
                Text('Pet: ${pet.name} (${pet.species.toString().split('.').last})'),
                const SizedBox(height: 8),
              ],
              Text('Type: ${record.type.toString().split('.').last}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(record.recordDate)}'),
              if (record.nextDueDate != null) ...[
                const SizedBox(height: 8),
                Text('Next Due: ${DateFormat('MMM dd, yyyy').format(record.nextDueDate!)}'),
              ],
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(record.description),
              if (record.medication != null) ...[
                const SizedBox(height: 8),
                const Text('Medication:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.medication!),
              ],
              if (record.dosage != null) ...[
                const SizedBox(height: 8),
                const Text('Dosage:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.dosage!),
              ],
              if (record.notes != null) ...[
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleRecordAction(String action, HealthRecordModel record) async {
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    switch (action) {
      case 'view':
        _showRecordDetails(record);
        break;
      case 'edit':
        // Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmation(record);
        if (confirmed) {
          await healthService.deleteHealthRecord(record.id);
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully')),
          );
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(HealthRecordModel record) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Health Record'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Color _getRecordTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return VetHealthRecordsTheme.softGreen;
      case HealthRecordType.medication:
        return VetHealthRecordsTheme.accentGold;
      case HealthRecordType.checkup:
        return VetHealthRecordsTheme.warmRed;
      case HealthRecordType.surgery:
        return VetHealthRecordsTheme.darkBrown;
      case HealthRecordType.allergy:
        return VetHealthRecordsTheme.warmPurple;
      case HealthRecordType.injury:
        return VetHealthRecordsTheme.lightBrown;
      case HealthRecordType.other:
        return VetHealthRecordsTheme.primaryBrown.withOpacity(0.7);
    }
  }

  IconData _getRecordTypeIcon(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Icons.vaccines;
      case HealthRecordType.medication:
        return Icons.medication;
      case HealthRecordType.checkup:
        return Icons.health_and_safety;
      case HealthRecordType.surgery:
        return Icons.medical_services;
      case HealthRecordType.allergy:
        return Icons.warning;
      case HealthRecordType.injury:
        return Icons.healing;
      case HealthRecordType.other:
        return Icons.medical_information;
    }
  }

  IconData _getPetSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets;
      case PetSpecies.bird:
        return Icons.flight;
      case PetSpecies.rabbit:
        return Icons.pets;
      case PetSpecies.hamster:
        return Icons.pets;
      case PetSpecies.fish:
        return Icons.water;
      case PetSpecies.reptile:
        return Icons.pets;
      case PetSpecies.other:
        return Icons.pets;
    }
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays;
    
    if (age < 30) {
      return '$age days old';
    } else if (age < 365) {
      final months = (age / 30).floor();
      return '$months months old';
    } else {
      final years = (age / 365).floor();
      final remainingMonths = ((age % 365) / 30).floor();
      return remainingMonths > 0 ? '$years years $remainingMonths months old' : '$years years old';
    }
  }
}
