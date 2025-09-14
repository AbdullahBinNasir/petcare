import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../shared/profile_screen.dart';
import '../shared/appointments_screen.dart';
import '../shared/pet_store_screen.dart';
import '../shared/blog_screen.dart';
import '../shared/admin_store_management_screen.dart';
import '../shared/admin_blog_management_screen.dart';

class ShelterDashboard extends StatefulWidget {
  const ShelterDashboard({super.key});

  @override
  State<ShelterDashboard> createState() => _ShelterDashboardState();
}

class _ShelterDashboardState extends State<ShelterDashboard> {
  int _currentIndex = 0;

  // Custom color scheme with your specified colors
  static const Color primaryBeige = Color(0xFFF5F5DC);  // Your beige color
  static const Color primaryBrown = Color(0xFF4D270E);  // Your dark brown color
  static const Color lightBrown = Color(0xFF7A4A1A);    // Lighter shade of your brown
  static const Color accentOrange = Color(0xFFD2691E);  // Complementary orange
  static const Color softGreen = Color(0xFF6B8E23);     // Olive green that works with beige/brown
  static const Color warmPurple = Color(0xFF8B7355);    // Warm taupe purple

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const AppointmentsScreen(),
      const PetStoreScreen(),
      const BlogScreen(),
      const AdminStoreManagementScreen(),
      const AdminBlogManagementScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryBrown,
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedFontSize: 12,
          unselectedFontSize: 10,
          selectedItemColor: primaryBeige,
          unselectedItemColor: primaryBeige.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Blog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Store Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Blog Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: primaryBeige,
      appBar: AppBar(
        title: Text(
          'Shelter Dashboard',
          style: TextStyle(
            color: primaryBeige,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryBrown,
        elevation: 2,
        shadowColor: primaryBrown.withOpacity(0.3),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: primaryBeige.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications,
                color: primaryBeige,
              ),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthService>(
              builder: (context, authService, child) {
                final user = authService.currentUserModel;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryBrown.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrown.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: primaryBrown,
                          child: Icon(
                            Icons.home,
                            color: primaryBeige,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Shelter Admin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryBrown,
                                ),
                              ),
                              if (user?.shelterName != null)
                                Text(
                                  user!.shelterName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryBrown.withOpacity(0.7),
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
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Available Pets',
                    '12',
                    Icons.pets,
                    accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending Requests',
                    '5',
                    Icons.request_page,
                    lightBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Successful Adoptions',
                    '28',
                    Icons.favorite,
                    softGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'This Month',
                    '3',
                    Icons.calendar_month,
                    warmPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activities
            Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBrown.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBrown.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActivityItem(
                      'New adoption request for Max',
                      '2 hours ago',
                      Icons.request_page,
                      lightBrown,
                    ),
                    Divider(color: primaryBrown.withOpacity(0.1)),
                    _buildActivityItem(
                      'Bella was successfully adopted',
                      '1 day ago',
                      Icons.favorite,
                      softGreen,
                    ),
                    Divider(color: primaryBrown.withOpacity(0.1)),
                    _buildActivityItem(
                      'Added new pet: Charlie',
                      '2 days ago',
                      Icons.pets,
                      accentOrange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Manage Store',
                    Icons.admin_panel_settings,
                    primaryBrown,
                    () => setState(() => _currentIndex = 4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Manage Blog',
                    Icons.edit,
                    accentOrange,
                    () => setState(() => _currentIndex = 5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBrown.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBrown.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryBrown,
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

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryBrown,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}