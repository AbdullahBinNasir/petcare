import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/health_record_service.dart';
import '../../models/appointment_model.dart';
import '../../models/health_record_model.dart';
import '../../theme/pet_care_theme.dart';
import '../shared/profile_screen.dart';
import '../shared/blog_screen.dart';
import 'vet_health_records_screen.dart';
import 'vet_pet_search_screen.dart';
import 'vet_appointment_calendar_screen.dart';

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<AppointmentModel> _todaysAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<HealthRecordModel> _recentHealthRecords = [];
  int _totalPatients = 0;
  int _totalHealthRecords = 0;
  bool _isLoading = true;
  
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

  Future<void> _loadDashboardData() async {
    print('🏥 VetDashboard: Starting to load dashboard data...');
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final healthService = Provider.of<HealthRecordService>(context, listen: false);

    print('👤 VetDashboard: Current user: ${authService.currentUser?.uid}');
    print('👤 VetDashboard: Current user model: ${authService.currentUserModel?.firstName} ${authService.currentUserModel?.lastName}');

    if (authService.currentUser != null) {
      print('📅 VetDashboard: Loading appointments...');
      final todaysAppointments = await appointmentService.getTodaysAppointments(authService.currentUser!.uid);
      final upcomingAppointments = await appointmentService.getUpcomingAppointments(authService.currentUser!.uid, isVet: true);
      
      print('🏥 VetDashboard: Loading health records for vet ID: ${authService.currentUser!.uid}');
      final healthRecords = await healthService.getHealthRecordsByVetId(authService.currentUser!.uid);
      print('📊 VetDashboard: Received ${healthRecords.length} health records from service');
      
      // Get unique patient count from appointments
      final patientIds = <String>{};
      for (final appointment in todaysAppointments) {
        patientIds.add(appointment.petId);
      }
      for (final appointment in upcomingAppointments) {
        patientIds.add(appointment.petId);
      }

      print('📊 VetDashboard: Setting state with data:');
      print('  - Today\'s appointments: ${todaysAppointments.length}');
      print('  - Upcoming appointments: ${upcomingAppointments.length}');
      print('  - Health records: ${healthRecords.length}');
      print('  - Recent health records (first 5): ${healthRecords.take(5).length}');
      print('  - Total patients: ${patientIds.length}');
      
      setState(() {
        _todaysAppointments = todaysAppointments;
        _upcomingAppointments = upcomingAppointments;
        _recentHealthRecords = healthRecords.take(5).toList();
        _totalPatients = patientIds.length;
        _totalHealthRecords = healthRecords.length;
        _isLoading = false;
      });
      
      // Start animations after data is loaded
      _slideAnimationController.forward();
      _fadeAnimationController.forward();
      _scaleAnimationController.forward();
      
      print('✅ VetDashboard: State updated successfully');
      print('📊 VetDashboard: Final _recentHealthRecords length: ${_recentHealthRecords.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const VetPetSearchScreen(),
      const VetAppointmentCalendarScreen(),
      const BlogScreen(),
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
      bottomNavigationBar: Container(
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
          unselectedItemColor: PetCareTheme.lightBrown.withOpacity(0.7),
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
              icon: Icon(Icons.pets_rounded, size: 24),
              activeIcon: Icon(Icons.pets_rounded, size: 26),
              label: 'Pets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded, size: 24),
              activeIcon: Icon(Icons.calendar_month_rounded, size: 26),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_rounded, size: 24),
              activeIcon: Icon(Icons.article_rounded, size: 26),
              label: 'Blog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 24),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
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
          'Veterinary Dashboard',
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
              color: PetCareTheme.primaryBeige.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PetCareTheme.primaryBeige.withOpacity(0.3),
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
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PetCareTheme.cardWhite.withOpacity(0.8),
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
            )
          : RefreshIndicator(
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
                            // Welcome Section
                            Consumer<AuthService>(
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
                                              color: PetCareTheme.primaryBeige.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: PetCareTheme.primaryBeige.withOpacity(0.4),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.medical_services_rounded,
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
                                                    color: PetCareTheme.primaryBeige.withOpacity(0.9),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Dr. ${user?.fullName ?? 'Veterinarian'}',
                                                  style: TextStyle(
                                                    color: PetCareTheme.primaryBeige,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                if (user?.clinicName != null) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: PetCareTheme.primaryBeige.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user!.clinicName!,
                                                      style: TextStyle(
                                                        color: PetCareTheme.primaryBeige,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Quick Stats Header
                            Text(
                              'Today\'s Overview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PetCareTheme.primaryBrown,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Quick Stats Grid Layout (Always 2x2)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                final spacing = 16.0;
                                
                                // Always show 2x2 grid layout
                                return Column(
                                  children: [
                                    // First Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildResponsiveStatCard(
                                            'Today\'s Appointments',
                                            _todaysAppointments.length.toString(),
                                            Icons.today_rounded,
                                            PetCareTheme.accentGold,
                                            screenWidth,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: _buildResponsiveStatCard(
                                            'Upcoming',
                                            _upcomingAppointments.length.toString(),
                                            Icons.schedule_rounded,
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
                                            'Total Patients',
                                            _totalPatients.toString(),
                                            Icons.pets_rounded,
                                            PetCareTheme.warmRed,
                                            screenWidth,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: _buildResponsiveStatCard(
                                            'Health Records',
                                            _totalHealthRecords.toString(),
                                            Icons.medical_services_rounded,
                                            PetCareTheme.warmPurple,
                                            screenWidth,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 36),

                            // Today's Appointments Section Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today\'s Appointments',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: PetCareTheme.primaryBrown,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (_todaysAppointments.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [PetCareTheme.accentGold.withOpacity(0.2), PetCareTheme.lightBrown.withOpacity(0.2)],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: PetCareTheme.accentGold.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () => setState(() => _currentIndex = 2),
                                        child: Text(
                                          'View Calendar',
                                          style: TextStyle(
                                            color: PetCareTheme.primaryBrown,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Appointments content would go here
                            // ... (appointments list implementation)

                            const SizedBox(height: 32),

                            // Quick Actions
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PetCareTheme.primaryBrown,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quick Actions Grid Layout (2x2)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                final spacing = 16.0;
                                
                                return Column(
                                  children: [
                                    // First Row - Calendar and Health Records
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildResponsiveActionCard(
                                            'View Calendar',
                                            Icons.calendar_month_rounded,
                                            PetCareTheme.accentGold,
                                            () => setState(() => _currentIndex = 2),
                                            screenWidth,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: _buildResponsiveActionCard(
                                            'Pet Search',
                                            Icons.pets_rounded,
                                            PetCareTheme.primaryBrown,
                                            () => setState(() => _currentIndex = 1),
                                            screenWidth,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing),
                                    // Second Row - Blog and Health Records
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildResponsiveActionCard(
                                            'Blog',
                                            Icons.article_rounded,
                                            PetCareTheme.warmRed,
                                            () => setState(() => _currentIndex = 3),
                                            screenWidth,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: _buildResponsiveActionCard(
                                            'Health Records',
                                            Icons.medical_services_rounded,
                                            PetCareTheme.softGreen,
                                            () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const VetHealthRecordsScreen(),
                                                ),
                                              );
                                            },
                                            screenWidth,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
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
                  color: color.withOpacity(0.2),
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
                    color: color.withOpacity(0.1),
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
                      color.withOpacity(0.05),
                      color.withOpacity(0.02),
                      Colors.white.withOpacity(0.8),
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
                              color.withOpacity(0.2),
                              color.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
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
                              color: PetCareTheme.lightBrown.withOpacity(0.9),
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

  Widget _buildResponsiveActionCard(String title, IconData icon, Color color, VoidCallback onTap, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
              decoration: BoxDecoration(
                color: PetCareTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PetCareTheme.shadowColor,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: color.withOpacity(0.1),
                  highlightColor: color.withOpacity(0.05),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.03),
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12.0 : 16.0,
                        vertical: isSmallScreen ? 12.0 : 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: isSmallScreen ? 20.0 : 24.0,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8.0 : 12.0),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.0 : 11.0,
                              fontWeight: FontWeight.w600,
                              color: PetCareTheme.primaryBrown,
                              letterSpacing: 0.2,
                              height: 1.1,
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

}
