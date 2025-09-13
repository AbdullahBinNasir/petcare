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

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> {
  int _currentIndex = 0;
  List<AppointmentModel> _todaysAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<HealthRecordModel> _recentHealthRecords = [];
  int _totalPatients = 0;
  int _totalHealthRecords = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Health Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pet Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Blog',
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
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final user = authService.currentUserModel;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.green,
                                  child: const Icon(
                                    Icons.medical_services,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. ${user?.fullName ?? 'Veterinarian'}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (user?.clinicName != null)
                                        Text(
                                          user!.clinicName!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                            'Today\'s Appointments',
                            _todaysAppointments.length.toString(),
                            Icons.today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Upcoming',
                            _upcomingAppointments.length.toString(),
                            Icons.schedule,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Patients',
                            _totalPatients.toString(),
                            Icons.pets,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Health Records',
                            _totalHealthRecords.toString(),
                            Icons.medical_services,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today's Appointments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Appointments',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_todaysAppointments.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _currentIndex = 2),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_todaysAppointments.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No appointments today',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enjoy your free day!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_todaysAppointments.take(5).map((appointment) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getAppointmentStatusColor(appointment.status),
                              child: Icon(
                                _getAppointmentTypeIcon(appointment.type),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text('Pet ID: ${appointment.petId}'),
                            subtitle: Text(
                              '${appointment.timeSlot} • ${appointment.type.toString().split('.').last}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                            onTap: () {
                              // TODO: Navigate to appointment details
                            },
                          ),
                        );
                      }).toList()),

                    const SizedBox(height: 24),

                    // Recent Health Records
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Health Records',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_recentHealthRecords.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _currentIndex = 3),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Debug info for health records
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🐛 DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                          Text('_recentHealthRecords.length: ${_recentHealthRecords.length}'),
                          Text('_isLoading: $_isLoading'),
                          Text('_totalHealthRecords: $_totalHealthRecords'),
                          if (_recentHealthRecords.isNotEmpty) ...[
                            Text('First record title: ${_recentHealthRecords.first.title}'),
                            Text('First record type: ${_recentHealthRecords.first.type}'),
                          ],
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _testFetchAllRecords,
                            child: const Text('Test Fetch All Records'),
                          ),
                        ],
                      ),
                    ),

                    if (_recentHealthRecords.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No recent health records',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Health records will appear here after appointments',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_recentHealthRecords.take(3).map((record) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRecordTypeColor(record.type).withOpacity(0.1),
                              child: Icon(
                                _getRecordTypeIcon(record.type),
                                color: _getRecordTypeColor(record.type),
                                size: 20,
                              ),
                            ),
                            title: Text(record.title),
                            subtitle: Text(
                              '${DateFormat('MMM dd, yyyy').format(record.recordDate)} • ${record.type.toString().split('.').last}',
                            ),
                            onTap: () {
                              // TODO: Navigate to health record details
                            },
                          ),
                        );
                      }).toList()),

                    const SizedBox(height: 24),

                    // Quick Actions
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
                            'View Calendar',
                            Icons.calendar_month,
                            Colors.blue,
                            () => setState(() => _currentIndex = 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Health Records',
                            Icons.medical_services,
                            Colors.orange,
                            () => setState(() => _currentIndex = 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Pet Search',
                            Icons.pets,
                            Colors.purple,
                            () => setState(() => _currentIndex = 4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Availability',
                            Icons.schedule,
                            Colors.teal,
                            () => setState(() => _currentIndex = 5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Filter Appointments',
                            Icons.filter_list,
                            Colors.indigo,
                            () => setState(() => _currentIndex = 6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Manage Blog',
                            Icons.admin_panel_settings,
                            Colors.green,
                            () => setState(() => _currentIndex = 7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
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
    );
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

  Color _getRecordTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Colors.green;
      case HealthRecordType.medication:
        return Colors.blue;
      case HealthRecordType.checkup:
        return Colors.orange;
      case HealthRecordType.surgery:
        return Colors.red;
      case HealthRecordType.allergy:
        return Colors.purple;
      case HealthRecordType.injury:
        return Colors.red.shade800;
      case HealthRecordType.other:
        return Colors.grey;
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
