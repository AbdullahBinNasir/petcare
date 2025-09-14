import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../services/adoption_request_service.dart';
import '../../services/success_story_service.dart';
import '../../services/contact_volunteer_form_service.dart';
import 'pet_listing_management_screen.dart';
import 'adoption_request_management_screen.dart';
import 'success_story_management_screen.dart';
import 'contact_volunteer_form_management_screen.dart';

class ShelterOwnerDashboard extends StatefulWidget {
  const ShelterOwnerDashboard({super.key});

  @override
  State<ShelterOwnerDashboard> createState() => _ShelterOwnerDashboardState();
}

class _ShelterOwnerDashboardState extends State<ShelterOwnerDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late String _shelterOwnerId;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced color scheme with your exact specified colors
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

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _shelterOwnerId = authService.currentUserModel?.id ?? '';
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBeige,
      appBar: AppBar(
        title: Text(
          'Shelter Owner Dashboard',
          style: TextStyle(
            color: primaryBeige,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryBrown,
        foregroundColor: primaryBeige,
        elevation: 8,
        shadowColor: shadowColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBrown, darkBrown],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: primaryBeige.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBeige.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: primaryBeige, size: 22),
              onPressed: () => _showLogoutDialog(),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildDashboardHome(),
            ),
          ),
          const PetListingManagementScreen(),
          const AdoptionRequestManagementScreen(),
          const SuccessStoryManagementScreen(),
          const ContactVolunteerFormManagementScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBrown, darkBrown],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: accentGold,
          unselectedItemColor: primaryBeige.withOpacity(0.7),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded),
              label: 'Pet Listings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Adoption Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.celebration_rounded),
              label: 'Success Stories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contact_mail_rounded),
              label: 'Forms',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding based on screen width
        double horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Enhanced Welcome Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBrown, lightBrown, darkBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: primaryBrown.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentGold, accentGold.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Your Shelter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryBeige.withOpacity(0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryBeige,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Manage your pet listings, adoption requests, success stories, and volunteer forms all in one beautifully designed place.',
                      style: TextStyle(
                        fontSize: 15,
                        color: primaryBeige.withOpacity(0.95),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Quick Stats Section
          Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBrown,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildEnhancedQuickStats(),

          const SizedBox(height: 32),

          // Recent Activity Section
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBrown,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildEnhancedRecentActivity(),

          const SizedBox(height: 32),

          // Quick Actions Section
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBrown,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildEnhancedQuickActions(),
          const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedQuickStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getCombinedStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBrown),
                strokeWidth: 3,
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Pet Listings',
                    stats['petListings']?.toString() ?? '0',
                    Icons.pets_rounded,
                    accentGold,
                    'Available pets',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Adoption Requests',
                    stats['adoptionRequests']?.toString() ?? '0',
                    Icons.favorite_rounded,
                    warmRed,
                    'Pending requests',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Success Stories',
                    stats['successStories']?.toString() ?? '0',
                    Icons.celebration_rounded,
                    softGreen,
                    'Happy endings',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Volunteer Forms',
                    stats['forms']?.toString() ?? '0',
                    Icons.contact_mail_rounded,
                    warmPurple,
                    'New applications',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryBrown,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: primaryBrown.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBrown.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildEnhancedActivityItem(
              Icons.pets_rounded,
              'New pet listing added',
              '2 hours ago',
              accentGold,
            ),
            const Divider(height: 32, color: Color(0xFFEAE4D3)),
            _buildEnhancedActivityItem(
              Icons.favorite_rounded,
              'New adoption request received',
              '4 hours ago',
              warmRed,
            ),
            const Divider(height: 32, color: Color(0xFFEAE4D3)),
            _buildEnhancedActivityItem(
              Icons.celebration_rounded,
              'Success story published',
              '1 day ago',
              softGreen,
            ),
            const Divider(height: 32, color: Color(0xFFEAE4D3)),
            _buildEnhancedActivityItem(
              Icons.contact_mail_rounded,
              'New volunteer form submitted',
              '2 days ago',
              warmPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActivityItem(
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryBrown,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  color: primaryBrown.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBrown.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: primaryBrown.withOpacity(0.5),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEnhancedActionCard(
                'Add Pet Listing',
                'Register new pets',
                Icons.add_circle_rounded,
                accentGold,
                () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEnhancedActionCard(
                'View Requests',
                'Check adoption requests',
                Icons.favorite_rounded,
                warmRed,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedActionCard(
                'Success Stories',
                'Share happy endings',
                Icons.celebration_rounded,
                softGreen,
                () => setState(() => _selectedIndex = 3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEnhancedActionCard(
                'Volunteer Forms',
                'Manage applications',
                Icons.contact_mail_rounded,
                warmPurple,
                () => setState(() => _selectedIndex = 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8), color.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, int>> _getCombinedStats() async {
    try {
      final petListingService = Provider.of<PetListingService>(
        context,
        listen: false,
      );
      final adoptionRequestService = Provider.of<AdoptionRequestService>(
        context,
        listen: false,
      );
      final successStoryService = Provider.of<SuccessStoryService>(
        context,
        listen: false,
      );
      final formService = Provider.of<ContactVolunteerFormService>(
        context,
        listen: false,
      );

      final petListings = await petListingService
          .getPetListingsByShelterOwnerId(_shelterOwnerId);
      final adoptionRequests = await adoptionRequestService
          .getAdoptionRequestsByShelterOwnerId(_shelterOwnerId);
      final successStories = await successStoryService
          .getSuccessStoriesByShelterOwnerId(_shelterOwnerId);
      print('🔍 Loading forms for shelter owner ID: $_shelterOwnerId');
      final forms = await formService.getFormsByShelterOwnerId(_shelterOwnerId);
      print('📊 Found ${forms.length} forms for shelter owner');

      return {
        'petListings': petListings.length,
        'adoptionRequests': adoptionRequests.length,
        'successStories': successStories.length,
        'forms': forms.length,
      };
    } catch (e) {
      print('Error getting combined stats: $e');
      return {};
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryBrown.withOpacity(0.2), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warmRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: warmRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: primaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Are you sure you want to logout from your account?',
              style: TextStyle(
                color: primaryBrown.withOpacity(0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: primaryBrown.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBrown, darkBrown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show enhanced loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryBrown,
                              ),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Logging out...',
                              style: TextStyle(
                                color: primaryBrown,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  try {
                    await Provider.of<AuthService>(
                      context,
                      listen: false,
                    ).signOut();
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading dialog
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error during logout: $e',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: warmRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}