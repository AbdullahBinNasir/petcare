import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/appointment_service.dart';
import '../../models/pet_model.dart';
import '../../models/appointment_model.dart';
import '../../theme/pet_care_theme.dart';
import '../shared/profile_screen.dart';
import '../shared/pet_store_screen.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'pet_adoption_screen.dart';
import 'success_stories_screen.dart';
import 'contact_volunteer_form_screen.dart';
import '../../models/contact_volunteer_form_model.dart';

class PetOwnerDashboard extends StatefulWidget {
  const PetOwnerDashboard({super.key});

  @override
  State<PetOwnerDashboard> createState() => _PetOwnerDashboardState();
}

class _PetOwnerDashboardState extends State<PetOwnerDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<PetModel> _pets = [];
  List<AppointmentModel> _upcomingAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _debugEverything() async {
    print('\n======= COMPLETE DEBUG START =======');
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      print('1. USER CHECK:');
      print('   - Current User: ${currentUser?.uid}');
      print('   - User Email: ${currentUser?.email}');
      print('   - User Display Name: ${currentUser?.displayName}');
      print('   - User is null: ${currentUser == null}');
      
      if (currentUser == null) {
        print('   ❌ USER NOT AUTHENTICATED - STOPPING DEBUG');
        return;
      }
      
      print('\n2. FIRESTORE CONNECTION TEST:');
      try {
        await FirebaseFirestore.instance
            .collection('test')
            .doc('connection')
            .get();
        print('   ✅ Firestore connection working');
      } catch (e) {
        print('   ❌ Firestore connection error: $e');
      }
      
      print('\n3. ALL PETS IN DATABASE:');
      final allPetsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .get();
      
      print('   - Total pets in database: ${allPetsSnapshot.docs.length}');
      
      if (allPetsSnapshot.docs.isEmpty) {
        print('   ❌ NO PETS IN DATABASE AT ALL');
        print('   → You need to add a pet first');
      } else {
        for (var doc in allPetsSnapshot.docs) {
          final data = doc.data();
          print('   Pet ID: ${doc.id}');
          print('   Pet Name: ${data['name']}');
          print('   Owner ID: ${data['ownerId']}');
          print('   Is Active: ${data['isActive']}');
          print('   Matches Current User: ${data['ownerId'] == currentUser.uid}');
          print('   ---');
        }
      }
      
      print('\n4. PETS FOR CURRENT USER (NO FILTERS):');
      final userPetsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();
      
      print('   - User pets (any status): ${userPetsSnapshot.docs.length}');
      
      print('\n5. ACTIVE PETS FOR CURRENT USER:');
      final activePetsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('ownerId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('   - Active user pets: ${activePetsSnapshot.docs.length}');
      
      print('\n6. TESTING PET SERVICE:');
      final petService = Provider.of<PetService>(context, listen: false);
      final servicePets = await petService.getPetsByOwnerId(currentUser.uid);
      print('   - Pets from service: ${servicePets.length}');
      
      for (var pet in servicePets) {
        print('   Service Pet: ${pet.name} (ID: ${pet.id})');
      }
      
      print('\n7. TESTING ORDERED QUERY (EXACT DASHBOARD QUERY):');
      try {
        final orderedSnapshot = await FirebaseFirestore.instance
            .collection('pets')
            .where('ownerId', isEqualTo: currentUser.uid)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        print('   ✅ Ordered query successful: ${orderedSnapshot.docs.length} pets');
      } catch (e) {
        print('   ❌ Ordered query failed: $e');
        print('   → This might need a composite index in Firestore');
      }
      
    } catch (e) {
      print('❌ DEBUG ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    print('======= COMPLETE DEBUG END =======\n');
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Debug call
    await _debugEverything();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      final currentUser = authService.currentUser;
      print('LOAD DATA: Current user: ${currentUser?.uid}');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = currentUser.uid;
      print('LOAD DATA: Loading data for user: $userId');

      print('LOAD DATA: Fetching pets...');
      final pets = await petService.getPetsByOwnerId(userId);
      print('LOAD DATA: Fetched ${pets.length} pets: ${pets.map((p) => p.name).toList()}');

      print('LOAD DATA: Fetching appointments...');
      List<AppointmentModel> appointments = [];
      try {
        appointments = await appointmentService.getUpcomingAppointments(userId);
        print('LOAD DATA: Fetched ${appointments.length} appointments');
      } catch (e) {
        print('LOAD DATA: Error loading appointments (continuing without them): $e');
      }

      if (mounted) {
        setState(() {
          _pets = pets;
          _upcomingAppointments = appointments;
          _isLoading = false;
        });
        
        // Start animations after data is loaded
        _slideAnimationController.forward();
        _fadeAnimationController.forward();
        _scaleAnimationController.forward();
        
        print('LOAD DATA: UI updated with ${_pets.length} pets and ${_upcomingAppointments.length} appointments');
      }
    } catch (e) {
      print('LOAD DATA: Error loading dashboard data: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const PetStoreScreen(),
      const PetAdoptionScreen(),
      const SuccessStoriesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: PetCareTheme.primaryBrown,
        unselectedItemColor: PetCareTheme.lightBrown.withValues(alpha: 0.7),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded, size: 24),
            activeIcon: Icon(Icons.dashboard_rounded, size: 26),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded, size: 24),
            activeIcon: Icon(Icons.store_rounded, size: 26),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_rounded, size: 24),
            activeIcon: Icon(Icons.pets_rounded, size: 26),
            label: 'Adopt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_rounded, size: 24),
            activeIcon: Icon(Icons.auto_stories_rounded, size: 26),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 24),
            activeIcon: Icon(Icons.person_rounded, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildModernAppBar(),
      body: _buildHomeBody(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: PetCareTheme.primaryGradient,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: PetCareTheme.primaryBeige,
      title: Text(
        'Pet Owner Dashboard',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PetCareTheme.primaryBeige,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: PetCareTheme.primaryBeige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PetCareTheme.primaryBeige.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_rounded,
              color: PetCareTheme.primaryBeige,
              size: 24,
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ),
      ],
    );
  }


  Widget _buildHomeBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: PetCareTheme.primaryBrown,
      backgroundColor: PetCareTheme.cardWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildWelcomeSection(),
                    const SizedBox(height: 32),
                    _buildQuickStatsHeader(),
                    const SizedBox(height: 20),
                    _buildQuickStats(),
                    const SizedBox(height: 36),
                    _buildMyPetsSection(),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite.withValues(alpha: 0.8),
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
              'Loading Dashboard...',
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

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: PetCareTheme.cardBackground,
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
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: PetCareTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PetCareTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsHeader() {
    return Text(
      'Today\'s Overview',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: PetCareTheme.primaryBrown,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUserModel;
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: PetCareTheme.accentGradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: PetCareTheme.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: PetCareTheme.primaryBeige.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: PetCareTheme.primaryBeige.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.pets_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: PetCareTheme.primaryBeige.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user?.fullName ?? 'Pet Parent'}',
                          style: TextStyle(
                            color: PetCareTheme.primaryBeige,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PetCareTheme.primaryBeige.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pet Owner',
                            style: TextStyle(
                              color: PetCareTheme.primaryBeige,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final spacing = 16.0;
        
        // Calculate additional stats
        final totalAppointments = _upcomingAppointments.length;
        final healthRecords = 0; // Health records are managed separately
        
        // Always show 2x2 grid layout
        return Column(
          children: [
            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildResponsiveStatCard(
                    'My Pets',
                    _pets.length.toString(),
                    Icons.pets_rounded,
                    PetCareTheme.accentGold,
                    screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Appointments',
                    totalAppointments.toString(),
                    Icons.calendar_month_rounded,
                    PetCareTheme.softGreen,
                    screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Second Row
            Row(
              children: [
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Health Records',
                    healthRecords.toString(),
                    Icons.medical_services_rounded,
                    PetCareTheme.warmRed,
                    screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildResponsiveStatCard(
                    'Care Score',
                    '95%',
                    Icons.favorite_rounded,
                    PetCareTheme.warmPurple,
                    screenWidth,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveStatCard(String title, String value, IconData icon, Color color, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PetCareTheme.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.05),
                      color.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: isSmallScreen ? 16.0 : 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Section
                      Container(
                        width: isSmallScreen ? 48.0 : 56.0,
                        height: isSmallScreen ? 48.0 : 56.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isSmallScreen ? 24.0 : 28.0,
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                      
                      // Value Section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24.0 : 28.0,
                              fontWeight: FontWeight.w900,
                              color: PetCareTheme.primaryBrown,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4.0 : 6.0),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11.0 : 12.0,
                              fontWeight: FontWeight.w600,
                              color: PetCareTheme.lightBrown.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildMyPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Pets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: PetCareTheme.textDark,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: PetCareTheme.accentGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPetScreen()),
                    );
                    if (result == true) {
                      _loadDashboardData();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Pet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPetsList(),
      ],
    );
  }

  Widget _buildPetsList() {
    print('Building pets list with ${_pets.length} pets');
    
    if (_pets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: PetCareTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [PetCareTheme.cardShadow],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PetCareTheme.primaryBrown.withValues(alpha: 0.1),
                    PetCareTheme.lightBrown.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 50,
                color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No pets added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first pet to get started with tracking their health and appointments',
              style: TextStyle(
                fontSize: 16,
                color: PetCareTheme.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPetScreen()),
                );
                if (result == true) {
                  _loadDashboardData();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Pet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PetCareTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive height based on screen size
        final screenWidth = constraints.maxWidth;
        final cardHeight = screenWidth < 400 ? 300.0 : 320.0;
        
        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4), // Add padding to prevent edge clipping
            itemCount: _pets.length,
            itemBuilder: (context, index) {
              final pet = _pets[index];
              return Container(
                width: screenWidth < 400 ? 180 : 200, // Responsive width
                margin: EdgeInsets.only(
                  right: index == _pets.length - 1 ? 4 : 16, // Add right margin for last item
                  left: index == 0 ? 4 : 0, // Add left margin for first item
                ),
                child: _buildPetCard(pet),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallCard = constraints.maxWidth < 200;
        final cardPadding = isSmallCard ? 12.0 : 16.0;
        
        return Container(
          height: double.infinity, // Use all available height
          decoration: BoxDecoration(
            color: PetCareTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PetCareTheme.cardShadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PetProfileScreen(pet: pet),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Image Section - Fixed height to prevent overflow
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildPetImage(pet),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallCard ? 12 : 16),
                    
                    // Pet Info Section - Fixed height to prevent overflow
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Name
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: isSmallCard ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: PetCareTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: isSmallCard ? 4 : 6),
                          
                          // Pet Details
                          Text(
                            '${pet.breed.isNotEmpty ? pet.breed : pet.species.toString().split('.').last} • ${pet.ageString}',
                            style: TextStyle(
                              fontSize: isSmallCard ? 12 : 14,
                              color: PetCareTheme.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: isSmallCard ? 6 : 10),
                          
                          // Health Status Chip
                          _buildHealthStatusChip(pet.healthStatus, isSmall: isSmallCard),
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

  Widget _buildPetImage(PetModel pet) {
    if (pet.photoUrls.isNotEmpty) {
      return Image.network(
        pet.photoUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: PetCareTheme.primaryBrown,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPetPlaceholder(pet);
        },
      );
    }
    return _buildPetPlaceholder(pet);
  }

  Widget _buildPetPlaceholder(PetModel pet) {
    IconData icon;
    List<Color> gradientColors;
    
    switch (pet.species) {
      case PetSpecies.dog:
        icon = Icons.pets_rounded;
        gradientColors = [Colors.brown.shade300, Colors.brown.shade400];
        break;
      case PetSpecies.cat:
        icon = Icons.pets_rounded;
        gradientColors = [Colors.orange.shade300, Colors.orange.shade400];
        break;
      case PetSpecies.bird:
        icon = Icons.flutter_dash_rounded;
        gradientColors = [Colors.blue.shade300, Colors.blue.shade400];
        break;
      case PetSpecies.fish:
        icon = Icons.waves_rounded;
        gradientColors = [Colors.cyan.shade300, Colors.cyan.shade400];
        break;
      case PetSpecies.rabbit:
        icon = Icons.pets_rounded;
        gradientColors = [Colors.grey.shade300, Colors.grey.shade400];
        break;
      default:
        icon = Icons.pets_rounded;
        gradientColors = [Colors.grey.shade300, Colors.grey.shade400];
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHealthStatusChip(HealthStatus status, {bool isSmall = false}) {
    final (color, text, icon) = _getHealthStatusInfo(status);
    
    final chipPadding = isSmall 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    
    final iconSize = isSmall ? 10.0 : 12.0;
    final fontSize = isSmall ? 10.0 : 12.0;
    final spacing = isSmall ? 2.0 : 4.0;

    return Container(
      padding: chipPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: spacing),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getHealthStatusInfo(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return (Colors.green, 'HEALTHY', Icons.check_circle);
      case HealthStatus.sick:
        return (Colors.red, 'SICK', Icons.warning);
      case HealthStatus.recovering:
        return (Colors.orange, 'RECOVERING', Icons.healing);
      case HealthStatus.critical:
        return (Colors.red.shade800, 'CRITICAL', Icons.emergency);
      case HealthStatus.unknown:
        return (Colors.grey, 'UNKNOWN', Icons.help);
    }
  }


  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: PetCareTheme.textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Book Appointment',
                icon: Icons.calendar_today_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                ),
                onTap: () async {
                  if (_pets.isEmpty) {
                    _showNoPetsSnackBar();
                    return;
                  }
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookAppointmentScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadDashboardData();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Health Tracking',
                icon: Icons.health_and_safety_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
                ),
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Pet Store',
                icon: Icons.store_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Adopt a Pet',
                icon: Icons.pets_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF26A69A), Color(0xFF00695C)],
                ),
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Success Stories',
                icon: Icons.auto_stories_rounded,
                gradient: LinearGradient(colors: PetCareTheme.accentGradient),
                onTap: () => setState(() => _currentIndex = 5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Contact Us',
                icon: Icons.contact_mail_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                ),
                onTap: _showContactOptions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    // Extract the primary color from gradient for theming
    final primaryColor = gradient.colors.first;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: PetCareTheme.cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: PetCareTheme.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.05),
                        primaryColor.withValues(alpha: 0.02),
                        Colors.white.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Section
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withValues(alpha: 0.2),
                                primaryColor.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Title Section
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PetCareTheme.primaryBrown,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNoPetsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please add a pet first before booking an appointment'),
        backgroundColor: PetCareTheme.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Add Pet',
          textColor: Colors.white,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPetScreen()),
            );
            if (result == true) {
              _loadDashboardData();
            }
          },
        ),
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: PetCareTheme.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Contact Options',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PetCareTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),
              _buildContactOption(
                icon: Icons.contact_mail_rounded,
                title: 'General Contact',
                subtitle: 'Get in touch with us',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactVolunteerFormScreen(
                        formType: FormType.contact,
                      ),
                    ),
                  );
                },
              ),
              _buildContactOption(
                icon: Icons.volunteer_activism_rounded,
                title: 'Volunteer Application',
                subtitle: 'Join our volunteer team',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactVolunteerFormScreen(
                        formType: FormType.volunteer,
                      ),
                    ),
                  );
                },
              ),
              _buildContactOption(
                icon: Icons.attach_money_rounded,
                title: 'Donation Inquiry',
                subtitle: 'Support our cause',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactVolunteerFormScreen(
                        formType: FormType.donation,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: PetCareTheme.textDark,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: PetCareTheme.textLight,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

}