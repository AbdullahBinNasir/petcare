import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import '../../models/appointment_model.dart';
import '../../models/health_record_model.dart';
import '../shared/profile_screen.dart';
import '../shared/appointments_screen.dart';
import '../shared/blog_screen.dart';
import '../shared/admin_blog_management_screen.dart';
import 'vet_health_records_screen.dart';
import 'vet_pet_search_screen.dart';
import 'vet_appointment_completion_screen.dart';
import 'vet_availability_management_screen.dart';
import 'vet_appointment_filters_screen.dart';
import 'vet_appointment_calendar_screen.dart';

class VetTheme {
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
    final petService = Provider.of<PetService>(context, listen: false);

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

  Future<void> _testFetchAllRecords() async {
    print('🧪 VetDashboard: Testing fetch all records...');
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    final allRecords = await healthService.getAllHealthRecords();
    print('🧪 VetDashboard: Fetched ${allRecords.length} total records from all vets');
    
    if (allRecords.isNotEmpty) {
      print('🧪 VetDashboard: Sample records:');
      for (int i = 0; i < allRecords.length && i < 3; i++) {
        final record = allRecords[i];
        print('  Record ${i + 1}:');
        print('    ID: ${record.id}');
        print('    Title: ${record.title}');
        print('    Vet ID: ${record.veterinarianId}');
        print('    Pet ID: ${record.petId}');
        print('    Type: ${record.type}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const VetAppointmentCalendarScreen(),
      const AppointmentsScreen(),
      const VetHealthRecordsScreen(),
      const VetPetSearchScreen(),
      const VetAvailabilityManagementScreen(),
      const VetAppointmentFiltersScreen(),
      const BlogScreen(),
      const AdminBlogManagementScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: VetTheme.backgroundGradient,
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: VetTheme.cardWhite,
          boxShadow: [
            BoxShadow(
              color: VetTheme.shadowColor,
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
          selectedItemColor: VetTheme.primaryBrown,
          unselectedItemColor: VetTheme.lightBrown.withOpacity(0.7),
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
              icon: Icon(Icons.calendar_month_rounded, size: 24),
              activeIcon: Icon(Icons.calendar_month_rounded, size: 26),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded, size: 24),
              activeIcon: Icon(Icons.list_alt_rounded, size: 26),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_rounded, size: 24),
              activeIcon: Icon(Icons.medical_services_rounded, size: 26),
              label: 'Records',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded, size: 24),
              activeIcon: Icon(Icons.pets_rounded, size: 26),
              label: 'Pets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_rounded, size: 24),
              activeIcon: Icon(Icons.schedule_rounded, size: 26),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.filter_list_rounded, size: 24),
              activeIcon: Icon(Icons.filter_list_rounded, size: 26),
              label: 'Filters',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_rounded, size: 24),
              activeIcon: Icon(Icons.article_rounded, size: 26),
              label: 'Blog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_rounded, size: 24),
              activeIcon: Icon(Icons.edit_rounded, size: 26),
              label: 'Admin',
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
              colors: VetTheme.primaryGradient,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: VetTheme.primaryBeige,
        title: Text(
          'Veterinary Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: VetTheme.primaryBeige,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: VetTheme.primaryBeige.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VetTheme.primaryBeige.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_rounded,
                color: VetTheme.primaryBeige,
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
                  color: VetTheme.cardWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(VetTheme.primaryBrown),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Dashboard...',
                      style: TextStyle(
                        color: VetTheme.primaryBrown,
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
              color: VetTheme.primaryBrown,
              backgroundColor: VetTheme.cardWhite,
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
                                        colors: VetTheme.accentGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: VetTheme.shadowColor,
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
                                              color: VetTheme.primaryBeige.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: VetTheme.primaryBeige.withOpacity(0.4),
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
                                              color: VetTheme.primaryBeige,
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
                                                    color: VetTheme.primaryBeige.withOpacity(0.9),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Dr. ${user?.fullName ?? 'Veterinarian'}',
                                                  style: TextStyle(
                                                    color: VetTheme.primaryBeige,
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
                                                      color: VetTheme.primaryBeige.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user!.clinicName!,
                                                      style: TextStyle(
                                                        color: VetTheme.primaryBeige,
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
                      },
                            const SizedBox(height: 32),

                            // Quick Stats Header
                            Text(
                              'Today\'s Overview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: VetTheme.primaryBrown,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                    
                            // Quick Stats Responsive Layout
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                final isSmallScreen = screenWidth < 400;
                                final spacing = isSmallScreen ? 16.0 : 20.0;
                                
                                if (isSmallScreen) {
                                  // Single column layout for small screens
                                  return Column(
                                    children: [
                                      _buildResponsiveStatCard(
                                        'Today\'s Appointments',
                                        _todaysAppointments.length.toString(),
                                        Icons.today_rounded,
                                        VetTheme.accentGold,
                                        screenWidth,
                                      ),
                                      SizedBox(height: spacing),
                                      _buildResponsiveStatCard(
                                        'Upcoming',
                                        _upcomingAppointments.length.toString(),
                                        Icons.schedule_rounded,
                                        VetTheme.softGreen,
                                        screenWidth,
                                      ),
                                      SizedBox(height: spacing),
                                      _buildResponsiveStatCard(
                                        'Total Patients',
                                        _totalPatients.toString(),
                                        Icons.pets_rounded,
                                        VetTheme.warmRed,
                                        screenWidth,
                                      ),
                                      SizedBox(height: spacing),
                                      _buildResponsiveStatCard(
                                        'Health Records',
                                        _totalHealthRecords.toString(),
                                        Icons.medical_services_rounded,
                                        VetTheme.warmPurple,
                                        screenWidth,
                                      ),
                                    ],
                                  );
                                } else {
                                  // Two-column grid layout for larger screens
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildResponsiveStatCard(
                                              'Today\'s Appointments',
                                              _todaysAppointments.length.toString(),
                                              Icons.today_rounded,
                                              VetTheme.accentGold,
                                              screenWidth,
                                            ),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: _buildResponsiveStatCard(
                                              'Upcoming',
                                              _upcomingAppointments.length.toString(),
                                              Icons.schedule_rounded,
                                              VetTheme.softGreen,
                                              screenWidth,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildResponsiveStatCard(
                                              'Total Patients',
                                              _totalPatients.toString(),
                                              Icons.pets_rounded,
                                              VetTheme.warmRed,
                                              screenWidth,
                                            ),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: _buildResponsiveStatCard(
                                              'Health Records',
                                              _totalHealthRecords.toString(),
                                              Icons.medical_services_rounded,
                                              VetTheme.warmPurple,
                                              screenWidth,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
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
                                      color: VetTheme.primaryBrown,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (_todaysAppointments.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [VetTheme.accentGold.withOpacity(0.2), VetTheme.lightBrown.withOpacity(0.2)],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: VetTheme.accentGold.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () => setState(() => _currentIndex = 2),
                                        child: Text(
                                          'View All',
                                          style: TextStyle(
                                            color: VetTheme.primaryBrown,
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

                    if (_todaysAppointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: VetTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: VetTheme.primaryColor.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: VetTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                size: 48,
                                color: VetTheme.successColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No appointments today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: VetTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enjoy your free day!',
                              style: TextStyle(
                                fontSize: 14,
                                color: VetTheme.primaryColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_todaysAppointments.take(5).map((appointment) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: VetTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: VetTheme.primaryColor.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getAppointmentStatusColor(appointment.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getAppointmentTypeIcon(appointment.type),
                                color: _getAppointmentStatusColor(appointment.status),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              'Pet ID: ${appointment.petId}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: VetTheme.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${appointment.timeSlot} • ${appointment.type.toString().split('.').last}',
                                style: TextStyle(
                                  color: VetTheme.primaryColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getAppointmentStatusColor(appointment.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                appointment.status.toString().split('.').last.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getAppointmentStatusColor(appointment.status),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            onTap: () {
                              // TODO: Navigate to appointment details
                            },
                          ),
                        );
                      }).toList()),

                    const SizedBox(height: 32),

                    // Recent Health Records Section Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Health Records',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: VetTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_recentHealthRecords.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: VetTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextButton(
                                onPressed: () => setState(() => _currentIndex = 3),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: VetTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),


                    if (_recentHealthRecords.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: VetTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: VetTheme.primaryColor.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: VetTheme.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 48,
                                color: VetTheme.infoColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent health records',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: VetTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Health records will appear here after appointments',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: VetTheme.primaryColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_recentHealthRecords.take(3).map((record) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: VetTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: VetTheme.primaryColor.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getRecordTypeColor(record.type).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getRecordTypeIcon(record.type),
                                color: _getRecordTypeColor(record.type),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              record.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: VetTheme.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${DateFormat('MMM dd, yyyy').format(record.recordDate)} • ${record.type.toString().split('.').last}',
                                style: TextStyle(
                                  color: VetTheme.primaryColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            onTap: () {
                              // TODO: Navigate to health record details
                            },
                          ),
                        );
                      }).toList()),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: VetTheme.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions Responsive Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final isSmallScreen = screenWidth < 400;
                        final spacing = isSmallScreen ? 12.0 : 16.0;
                        
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _buildResponsiveActionCard(
                              'View Calendar',
                              Icons.calendar_month_rounded,
                              VetTheme.infoColor,
                              () => setState(() => _currentIndex = 1),
                              screenWidth,
                            ),
                            _buildResponsiveActionCard(
                              'Health Records',
                              Icons.medical_services_rounded,
                              VetTheme.primaryColor,
                              () => setState(() => _currentIndex = 3),
                              screenWidth,
                            ),
                            _buildResponsiveActionCard(
                              'Pet Search',
                              Icons.pets_rounded,
                              VetTheme.warningColor,
                              () => setState(() => _currentIndex = 4),
                              screenWidth,
                            ),
                            _buildResponsiveActionCard(
                              'Availability',
                              Icons.schedule_rounded,
                              VetTheme.successColor,
                              () => setState(() => _currentIndex = 5),
                              screenWidth,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildResponsiveStatCard(String title, String value, IconData icon, Color color, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    final cardHeight = isSmallScreen ? 140.0 : 150.0; // Increased height for better proportions
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
                color: VetTheme.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VetTheme.shadowColor,
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
                  padding: EdgeInsets.all(isSmallScreen ? 18.0 : 22.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon Section
                      Container(
                        width: isSmallScreen ? 56.0 : 64.0,
                        height: isSmallScreen ? 56.0 : 64.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isSmallScreen ? 28.0 : 32.0,
                        ),
                      ),
                      
                      // Value Section
                      Column(
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28.0 : 32.0,
                              fontWeight: FontWeight.w900,
                              color: VetTheme.primaryBrown,
                              letterSpacing: -0.8,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                              fontWeight: FontWeight.w700,
                              color: VetTheme.lightBrown.withOpacity(0.9),
                              letterSpacing: 0.3,
                              height: 1.2,
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
    final cardWidth = isSmallScreen ? screenWidth - 40 : (screenWidth - 56) / 2; // Account for padding and spacing
    final cardHeight = isSmallScreen ? 110.0 : 130.0;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: VetTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VetTheme.shadowColor,
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
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
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
                              size: isSmallScreen ? 26.0 : 30.0,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12.0 : 13.0,
                                fontWeight: FontWeight.w700,
                                color: VetTheme.primaryBrown,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return VetTheme.accentGold;
      case AppointmentStatus.confirmed:
        return VetTheme.softGreen;
      case AppointmentStatus.inProgress:
        return VetTheme.warmRed;
      case AppointmentStatus.completed:
        return VetTheme.softGreen.withOpacity(0.8);
      case AppointmentStatus.cancelled:
        return VetTheme.warmRed.withOpacity(0.7);
      case AppointmentStatus.noShow:
        return VetTheme.darkBrown;
    }
  }

  IconData _getAppointmentTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return Icons.health_and_safety;
      case AppointmentType.vaccination:
        return Icons.vaccines;
      case AppointmentType.surgery:
        return Icons.medical_services;
      case AppointmentType.emergency:
        return Icons.emergency;
      case AppointmentType.grooming:
        return Icons.content_cut;
      case AppointmentType.consultation:
        return Icons.chat;
    }
  }

  Color _getRecordTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return VetTheme.softGreen;
      case HealthRecordType.medication:
        return VetTheme.accentGold;
      case HealthRecordType.checkup:
        return VetTheme.warmRed;
      case HealthRecordType.surgery:
        return VetTheme.darkBrown;
      case HealthRecordType.allergy:
        return VetTheme.warmPurple;
      case HealthRecordType.injury:
        return VetTheme.lightBrown;
      case HealthRecordType.other:
        return VetTheme.primaryBrown.withOpacity(0.6);
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
}
