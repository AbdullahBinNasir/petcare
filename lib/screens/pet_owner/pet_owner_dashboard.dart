import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/appointment_service.dart';
import '../../models/pet_model.dart';
import '../../models/appointment_model.dart';
import '../shared/profile_screen.dart';
import '../shared/appointments_screen.dart';
import '../shared/pet_store_screen.dart';
import '../shared/blog_screen.dart';
import '../shared/global_search_screen.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'health_records_screen.dart';
import 'health_tracking_screen.dart';
import 'pet_adoption_screen.dart';
import 'success_stories_screen.dart';
import 'contact_volunteer_form_screen.dart';
import '../../models/contact_volunteer_form_model.dart';

class PetOwnerDashboard extends StatefulWidget {
  const PetOwnerDashboard({super.key});

  @override
  State<PetOwnerDashboard> createState() => _PetOwnerDashboardState();
}

class _PetOwnerDashboardState extends State<PetOwnerDashboard> {
  int _currentIndex = 0;
  List<PetModel> _pets = [];
  List<AppointmentModel> _upcomingAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
        final testDoc = await FirebaseFirestore.instance
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
      const AppointmentsScreen(),
      const HealthTrackingScreen(),
      const PetStoreScreen(),
      const PetAdoptionScreen(),
      const SuccessStoriesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Health Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Pet Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Adopt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pet Care Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugEverything,
            tooltip: 'Debug',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _buildHomeBody(),
    );
  }

  Widget _buildHomeBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your pets...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildMyPetsSection(),
            const SizedBox(height: 24),
            _buildUpcomingAppointments(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 80), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUserModel;
        final userName = user?.firstName ?? authService.currentUser?.displayName ?? 'User';
        final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $userName!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take great care of your pets today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
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
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'My Pets',
            _pets.length.toString(),
            Icons.pets,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Upcoming',
            _upcomingAppointments.length.toString(),
            Icons.calendar_today,
            Colors.green,
          ),
        ),
      ],
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPetScreen()),
                );
                if (result == true) {
                  _loadDashboardData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPetsList(),
      ],
    );
  }

  Widget _buildPetsList() {
    print('Building pets list with ${_pets.length} pets');
    
    if (_pets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No pets added yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet to get started with tracking their health and appointments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Pet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          print('Building pet card for: ${pet.name} (ID: ${pet.id})');
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 12),
            child: _buildPetCard(pet),
          );
        },
      ),
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPetImage(pet),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet.breed.isNotEmpty ? pet.breed : pet.species.toString().split('.').last} • ${pet.ageString}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildHealthStatusChip(pet.healthStatus),
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

  Widget _buildPetImage(PetModel pet) {
    print('Building image for pet: ${pet.name}, photos: ${pet.photoUrls}');
    
    if (pet.photoUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
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
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading pet image: $error');
            return _buildPetPlaceholder(pet);
          },
        ),
      );
    }
    return _buildPetPlaceholder(pet);
  }

  Widget _buildPetPlaceholder(PetModel pet) {
    IconData icon;
    Color color = Colors.grey[400]!;
    
    switch (pet.species) {
      case PetSpecies.dog:
        icon = Icons.pets;
        color = Colors.brown[400]!;
        break;
      case PetSpecies.cat:
        icon = Icons.pets;
        color = Colors.orange[400]!;
        break;
      case PetSpecies.bird:
        icon = Icons.flutter_dash;
        color = Colors.blue[400]!;
        break;
      case PetSpecies.fish:
        icon = Icons.waves;
        color = Colors.cyan[400]!;
        break;
      case PetSpecies.rabbit:
        icon = Icons.pets;
        color = Colors.grey[400]!;
        break;
      default:
        icon = Icons.pets;
        color = Colors.grey[400]!;
    }
    
    return Center(
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  Widget _buildHealthStatusChip(HealthStatus status) {
    final color = _getHealthStatusColor(status);
    final text = status.toString().split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_upcomingAppointments.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAppointmentsList(),
      ],
    );
  }

  Widget _buildAppointmentsList() {
    if (_upcomingAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No upcoming appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Book an appointment for your pet\'s health checkup',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _upcomingAppointments.take(3).map((appointment) {
        final pet = _pets.firstWhere(
          (p) => p.id == appointment.petId,
          orElse: () => PetModel(
            id: '',
            ownerId: '',
            name: 'Unknown Pet',
            species: PetSpecies.other,
            breed: '',
            gender: PetGender.unknown,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getAppointmentStatusColor(appointment.status),
              child: Icon(
                _getAppointmentTypeIcon(appointment.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              pet.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${appointment.type.toString().split('.').last} • ${appointment.timeSlot}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getAppointmentStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Book Appointment',
                Icons.calendar_today,
                Colors.blue,
                () async {
                  if (_pets.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add a pet first before booking an appointment'),
                      ),
                    );
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Health Tracking',
                Icons.health_and_safety,
                Colors.orange,
                () => setState(() => _currentIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Pet Store',
                Icons.store,
                Colors.green,
                () => setState(() => _currentIndex = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Adopt a Pet',
                Icons.pets,
                Colors.teal,
                () => setState(() => _currentIndex = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Success Stories',
                Icons.celebration,
                Colors.amber,
                () => setState(() => _currentIndex = 5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Contact Us',
                Icons.contact_mail,
                Colors.blue,
                () => _showContactOptions(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contact Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.contact_mail, color: Colors.blue),
                title: const Text('General Contact'),
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
              ListTile(
                leading: const Icon(Icons.volunteer_activism, color: Colors.green),
                title: const Text('Volunteer Application'),
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
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.orange),
                title: const Text('Donation Inquiry'),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.sick:
        return Colors.red;
      case HealthStatus.recovering:
        return Colors.orange;
      case HealthStatus.critical:
        return Colors.red.shade800;
      case HealthStatus.unknown:
      default:
        return Colors.grey;
    }
  }

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.red.shade800;
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
}