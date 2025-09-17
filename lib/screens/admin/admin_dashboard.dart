import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/contact_submission_service.dart';
import '../../services/feedback_submission_service.dart';
import '../../services/booking_statistics_service.dart';
import '../../services/store_service.dart';
import '../../services/order_service.dart';
import '../../models/contact_submission_model.dart';
import '../../models/feedback_submission_model.dart';
import '../../models/order_model.dart';
import '../../theme/pet_care_theme.dart';
import '../shared/profile_screen.dart';
import 'contact_management_screen.dart';
import 'feedback_management_screen.dart';
import '../shared/analytics_dashboard_screen.dart';
import '../shared/admin_store_management_screen.dart';
import '../shared/pet_store_screen.dart';
import '../shared/order_management_screen.dart';
import 'booking_analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<ContactSubmission> _recentContacts = [];
  List<FeedbackSubmission> _recentFeedbacks = [];
  List<OrderModel> _recentOrders = [];
  int _totalProducts = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _animationsInitialized = false;

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
    
    _animationsInitialized = true;
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contactService = Provider.of<ContactSubmissionService>(context, listen: false);
      final feedbackService = Provider.of<FeedbackSubmissionService>(context, listen: false);
      final bookingService = Provider.of<BookingStatisticsService>(context, listen: false);
      final storeService = Provider.of<StoreService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);

      await Future.wait([
        contactService.loadSubmissions(),
        feedbackService.loadSubmissions(),
        bookingService.loadBookingStatistics(),
        storeService.loadStoreItems(),
        orderService.loadOrders(),
      ]);

      if (mounted) {
        // Calculate store metrics
        final orders = orderService.orders;
        final products = storeService.storeItems;
        final revenue = orders.fold<double>(0.0, (sum, order) => sum + order.total);
        
        setState(() {
          _recentContacts = contactService.getRecentSubmissions();
          _recentFeedbacks = feedbackService.getRecentSubmissions();
          _recentOrders = orders.take(5).toList();
          _totalProducts = products.length;
          _totalOrders = orders.length;
          _totalRevenue = revenue;
          _isLoading = false;
        });
        
        // Start animations after data is loaded
        _slideAnimationController.forward();
        _fadeAnimationController.forward();
        _scaleAnimationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
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
      const AdminStoreManagementScreen(),
      const OrderManagementScreen(),
      const AnalyticsDashboardScreen(),
      const BookingAnalyticsScreen(),
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
        unselectedItemColor: PetCareTheme.lightBrown.withOpacity(0.7),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded, size: 20),
            activeIcon: Icon(Icons.dashboard_rounded, size: 22),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded, size: 20),
            activeIcon: Icon(Icons.store_rounded, size: 22),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded, size: 20),
            activeIcon: Icon(Icons.shopping_cart_rounded, size: 22),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded, size: 20),
            activeIcon: Icon(Icons.analytics_rounded, size: 22),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded, size: 20),
            activeIcon: Icon(Icons.calendar_today_rounded, size: 22),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 20),
            activeIcon: Icon(Icons.person_rounded, size: 22),
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
        'Admin Dashboard',
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
              Icons.refresh_rounded,
              color: PetCareTheme.primaryBeige,
              size: 24,
            ),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
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
        child: _animationsInitialized ? AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _animationsInitialized ? SlideTransition(
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
                    _buildRecentContacts(),
                    const SizedBox(height: 32),
                    _buildRecentFeedback(),
                    const SizedBox(height: 32),
                    _buildRecentOrders(),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ) : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildWelcomeSection(),
                  const SizedBox(height: 32),
                  _buildQuickStatsHeader(),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                  const SizedBox(height: 36),
                  _buildRecentContacts(),
                  const SizedBox(height: 32),
                  _buildRecentFeedback(),
                  const SizedBox(height: 32),
                  _buildRecentOrders(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildQuickStatsHeader(),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 36),
            _buildRecentContacts(),
            const SizedBox(height: 32),
            _buildRecentFeedback(),
            const SizedBox(height: 32),
            _buildQuickActions(),
            const SizedBox(height: 20),
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
      'System Overview',
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
        return _animationsInitialized ? ScaleTransition(
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
                      Icons.admin_panel_settings_rounded,
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
                          '${user?.fullName ?? 'Administrator'}',
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
                            color: PetCareTheme.primaryBeige.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'System Administrator',
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
        ) : Container(
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
                    Icons.admin_panel_settings_rounded,
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
                        '${user?.fullName ?? 'Administrator'}',
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
                          color: PetCareTheme.primaryBeige.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'System Administrator',
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
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer3<ContactSubmissionService, FeedbackSubmissionService, BookingStatisticsService>(
      builder: (context, contactService, feedbackService, bookingService, child) {
        final contactStats = contactService.getSubmissionStatistics();
        final feedbackStats = feedbackService.getSubmissionStatistics();
        final bookingStats = bookingService.statistics;

        return LayoutBuilder(
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
                        'Pending Contacts',
                        contactStats['pending']?.toString() ?? '0',
                        Icons.contact_support_rounded,
                        PetCareTheme.warmRed,
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildResponsiveStatCard(
                        'Pending Feedback',
                        feedbackStats['pending']?.toString() ?? '0',
                        Icons.feedback_rounded,
                        PetCareTheme.accentGold,
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
                        'Today\'s Bookings',
                        bookingStats['todayAppointments']?.toString() ?? '0',
                        Icons.today_rounded,
                        PetCareTheme.softGreen,
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildResponsiveStatCard(
                        'Total Bookings',
                        bookingStats['totalAppointments']?.toString() ?? '0',
                        Icons.event_rounded,
                        PetCareTheme.warmPurple,
                        screenWidth,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                // Third Row - Store Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildResponsiveStatCard(
                        'Products',
                        _totalProducts.toString(),
                        Icons.inventory_2_rounded,
                        PetCareTheme.accentGold,
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildResponsiveStatCard(
                        'Orders',
                        _totalOrders.toString(),
                        Icons.shopping_cart_checkout_rounded,
                        PetCareTheme.warmRed,
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
                        'Revenue',
                        '\$' + _totalRevenue.toStringAsFixed(2),
                        Icons.payments_rounded,
                        PetCareTheme.softGreen,
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Contact Submissions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PetCareTheme.primaryBrown,
                  letterSpacing: 0.5,
                ),
              ),
              if (_recentContacts.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PetCareTheme.warmRed.withOpacity(0.2), PetCareTheme.lightBrown.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: PetCareTheme.warmRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: null,
                    child: Text(
                      'View All',
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
        const SizedBox(height: 12),
        _recentContacts.isEmpty
            ? _buildEmptyState(
                icon: Icons.contact_support,
                title: 'No Recent Contacts',
                subtitle: 'No contact submissions in the last 7 days',
              )
            : Column(
                children: _recentContacts.take(3).map((contact) {
                  return _buildContactCard(contact);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildRecentFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Feedback Submissions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PetCareTheme.primaryBrown,
                  letterSpacing: 0.5,
                ),
              ),
              if (_recentFeedbacks.isNotEmpty)
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
                    onPressed: null,
                    child: Text(
                      'View All',
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
        const SizedBox(height: 12),
        _recentFeedbacks.isEmpty
            ? _buildEmptyState(
                icon: Icons.feedback,
                title: 'No Recent Feedback',
                subtitle: 'No feedback submissions in the last 7 days',
              )
            : Column(
                children: _recentFeedbacks.take(3).map((feedback) {
                  return _buildFeedbackCard(feedback);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PetCareTheme.primaryBrown,
                  letterSpacing: 0.5,
                ),
              ),
              if (_recentOrders.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PetCareTheme.softGreen.withOpacity(0.2), PetCareTheme.lightBrown.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: PetCareTheme.softGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: Text(
                      'View All',
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
        _recentOrders.isEmpty
            ? _buildEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'No Recent Orders',
                subtitle: 'No orders in the last 7 days',
              )
            : Column(
                children: _recentOrders.take(3).map((order) {
                  return _buildOrderCard(order);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PetCareTheme.cardShadow],
        border: Border.all(
          color: _getOrderStatusColor(order.status).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = 2),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getOrderStatusColor(order.status).withOpacity(0.2),
                        _getOrderStatusColor(order.status).withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: PetCareTheme.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getOrderStatusColor(order.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: _getOrderStatusColor(order.status),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${order.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PetCareTheme.primaryBrown,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: PetCareTheme.textMuted,
                            ),
                          ),
                        ],
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
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return PetCareTheme.accentGold;
      case OrderStatus.confirmed:
        return PetCareTheme.softGreen;
      case OrderStatus.processing:
        return PetCareTheme.primaryBrown;
      case OrderStatus.shipped:
        return PetCareTheme.warmPurple;
      case OrderStatus.delivered:
        return PetCareTheme.softGreen;
      case OrderStatus.cancelled:
        return PetCareTheme.warmRed;
      default:
        return PetCareTheme.lightBrown;
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                // First Row - Store and Order Management
                Row(
                  children: [
                    Expanded(
                      child: _buildResponsiveActionCard(
                        'Store Management',
                        Icons.store_rounded,
                        PetCareTheme.softGreen,
                        () => setState(() => _currentIndex = 1),
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildResponsiveActionCard(
                        'Order Management',
                        Icons.shopping_cart_checkout_rounded,
                        PetCareTheme.primaryBrown,
                        () => setState(() => _currentIndex = 2),
                        screenWidth,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                // Second Row - Analytics and Booking Analytics
                Row(
                  children: [
                    Expanded(
                      child: _buildResponsiveActionCard(
                        'Analytics',
                        Icons.analytics_rounded,
                        PetCareTheme.warmPurple,
                        () => setState(() => _currentIndex = 3),
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildResponsiveActionCard(
                        'Booking Analytics',
                        Icons.calendar_today_rounded,
                        PetCareTheme.accentGold,
                        () => setState(() => _currentIndex = 4),
                        screenWidth,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                // Third Row - Settings
                Row(
                  children: [
                    Expanded(
                      child: _buildResponsiveActionCard(
                        'Settings',
                        Icons.settings_rounded,
                        PetCareTheme.lightBrown,
                        () => setState(() => _currentIndex = 5),
                        screenWidth,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Container(), // Empty space for alignment
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveStatCard(String title, String value, IconData icon, Color color, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    
    return _animationsInitialized ? AnimatedBuilder(
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
    ) : Container(
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
    );
  }

  Widget _buildContactCard(ContactSubmission contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContactStatusColor(contact.status).withOpacity(0.1),
          child: Icon(
            Icons.contact_support,
            color: _getContactStatusColor(contact.status),
          ),
        ),
        title: Text(
          contact.subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${contact.name} (${contact.email})'),
            Text('Status: ${contact.statusDisplayName}'),
          ],
        ),
        trailing: Text(
          _formatDate(contact.submittedAt),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        onTap: null,
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackSubmission feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFeedbackStatusColor(feedback.status).withOpacity(0.1),
          child: Icon(
            Icons.feedback,
            color: _getFeedbackStatusColor(feedback.status),
          ),
        ),
        title: Text(
          feedback.subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${feedback.feedbackTypeDisplayName}'),
            Text('Rating: ${'★' * feedback.rating}'),
            Text('Status: ${feedback.statusDisplayName}'),
          ],
        ),
        trailing: Text(
          _formatDate(feedback.submittedAt),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        onTap: null,
      ),
    );
  }

  Widget _buildResponsiveActionCard(String title, IconData icon, Color color, VoidCallback onTap, double screenWidth) {
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400;
    
    return _animationsInitialized ? AnimatedBuilder(
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
    ) : Container(
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                  PetCareTheme.primaryBrown.withOpacity(0.1),
                  PetCareTheme.lightBrown.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: PetCareTheme.primaryBrown.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: PetCareTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: PetCareTheme.textLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getContactStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Colors.orange;
      case ContactStatus.inProgress:
        return Colors.blue;
      case ContactStatus.resolved:
        return Colors.green;
      case ContactStatus.closed:
        return Colors.grey;
    }
  }

  Color _getFeedbackStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Colors.orange;
      case FeedbackStatus.reviewed:
        return Colors.blue;
      case FeedbackStatus.acknowledged:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
