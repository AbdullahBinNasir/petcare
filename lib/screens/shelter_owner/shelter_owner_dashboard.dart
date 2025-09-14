import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/pet_listing_service.dart';
import '../../services/adoption_request_service.dart';
import '../../services/success_story_service.dart';
import '../../services/contact_volunteer_form_service.dart';
import '../../models/pet_listing_model.dart';
import '../../models/adoption_request_model.dart';
import '../../models/success_story_model.dart';
import '../../models/contact_volunteer_form_model.dart';
import 'pet_listing_management_screen.dart';
import 'adoption_request_management_screen.dart';
import 'success_story_management_screen.dart';
import 'contact_volunteer_form_management_screen.dart';

class ShelterOwnerDashboard extends StatefulWidget {
  const ShelterOwnerDashboard({super.key});

  @override
  State<ShelterOwnerDashboard> createState() => _ShelterOwnerDashboardState();
}

class _ShelterOwnerDashboardState extends State<ShelterOwnerDashboard> {
  int _selectedIndex = 0;
  late String _shelterOwnerId;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _shelterOwnerId = authService.currentUserModel?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Owner Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardHome(),
          const PetListingManagementScreen(),
          const AdoptionRequestManagementScreen(),
          const SuccessStoryManagementScreen(),
          const ContactVolunteerFormManagementScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pet Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Adoption Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration),
            label: 'Success Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: 'Forms',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Your Shelter Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your pet listings, adoption requests, success stories, and volunteer forms all in one place.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Text(
            'Quick Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickStats(),

          const SizedBox(height: 20),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentActivity(),

          const SizedBox(height: 20),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getCombinedStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pet Listings',
                stats['petListings']?.toString() ?? '0',
                Icons.pets,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Adoption Requests',
                stats['adoptionRequests']?.toString() ?? '0',
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildActivityItem(
              Icons.pets,
              'New pet listing added',
              '2 hours ago',
              Colors.blue,
            ),
            const Divider(),
            _buildActivityItem(
              Icons.favorite,
              'New adoption request received',
              '4 hours ago',
              Colors.red,
            ),
            const Divider(),
            _buildActivityItem(
              Icons.celebration,
              'Success story published',
              '1 day ago',
              Colors.green,
            ),
            const Divider(),
            _buildActivityItem(
              Icons.contact_mail,
              'New volunteer form submitted',
              '2 days ago',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Pet Listing',
                Icons.add_circle,
                Colors.blue,
                () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Requests',
                Icons.favorite,
                Colors.red,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Success Story',
                Icons.celebration,
                Colors.green,
                () => setState(() => _selectedIndex = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Forms',
                Icons.contact_mail,
                Colors.orange,
                () => setState(() => _selectedIndex = 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, int>> _getCombinedStats() async {
    try {
      final petListingService = Provider.of<PetListingService>(context, listen: false);
      final adoptionRequestService = Provider.of<AdoptionRequestService>(context, listen: false);
      final successStoryService = Provider.of<SuccessStoryService>(context, listen: false);
      final formService = Provider.of<ContactVolunteerFormService>(context, listen: false);

      final petListings = await petListingService.getPetListingsByShelterOwnerId(_shelterOwnerId);
      final adoptionRequests = await adoptionRequestService.getAdoptionRequestsByShelterOwnerId(_shelterOwnerId);
      final successStories = await successStoryService.getSuccessStoriesByShelterOwnerId(_shelterOwnerId);
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
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthService>(context, listen: false).signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
