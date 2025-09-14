import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/pet_service.dart';
import '../../theme/pet_care_theme.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  Map<String, PetModel> _pets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final petService = Provider.of<PetService>(context, listen: false);

    if (authService.currentUser != null) {
      final appointments = await appointmentService.getAppointmentsByPetOwner(
        authService.currentUser!.uid,
      );
      final pets = await petService.getPetsByOwnerId(authService.currentUser!.uid);

      // Create pets map for quick lookup
      final petsMap = <String, PetModel>{};
      for (final pet in pets) {
        petsMap[pet.id] = pet;
      }

      final now = DateTime.now();
      final upcoming = <AppointmentModel>[];
      final past = <AppointmentModel>[];

      for (final appointment in appointments) {
        if (appointment.appointmentDate.isAfter(now) || 
            appointment.appointmentDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
          upcoming.add(appointment);
        } else {
          past.add(appointment);
        }
      }

      // Sort appointments
      upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      past.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      setState(() {
        _upcomingAppointments = upcoming;
        _pastAppointments = past;
        _pets = petsMap;
        _isLoading = false;
      });
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
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingTab(),
                        _buildPastTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Appointments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: PetCareTheme.primaryBeige,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _loadAppointments(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: PetCareTheme.primaryBeige.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: PetCareTheme.primaryBeige,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: PetCareTheme.primaryBrown,
                unselectedLabelColor: PetCareTheme.primaryBeige.withValues(alpha: 0.7),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
              'Loading Appointments...',
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

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: PetCareTheme.accentGradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookAppointmentScreen(),
            ),
          );
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingAppointments.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [PetCareTheme.elevatedShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Icons.calendar_today_rounded,
                  size: 50,
                  color: PetCareTheme.primaryBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: PetCareTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Book your first appointment to get started with your pet\'s health care',
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
                    MaterialPageRoute(
                      builder: (context) => const BookAppointmentScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadAppointments();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Book Appointment'),
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: PetCareTheme.primaryBrown,
      backgroundColor: PetCareTheme.cardWhite,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
          final pet = _pets[appointment.petId];
          return _buildAppointmentCard(appointment, pet, true);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_pastAppointments.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: PetCareTheme.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [PetCareTheme.elevatedShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PetCareTheme.lightBrown.withValues(alpha: 0.1),
                      PetCareTheme.warmPurple.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 50,
                  color: PetCareTheme.lightBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Past Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: PetCareTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your appointment history will appear here once you have completed appointments',
                style: TextStyle(
                  fontSize: 16,
                  color: PetCareTheme.textLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: PetCareTheme.primaryBrown,
      backgroundColor: PetCareTheme.cardWhite,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _pastAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _pastAppointments[index];
          final pet = _pets[appointment.petId];
          return _buildAppointmentCard(appointment, pet, false);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, PetModel? pet, bool isUpcoming) {
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pet info and status
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.1),
                        statusColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet?.name ?? 'Unknown Pet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PetCareTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAppointmentTypeName(appointment.type),
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusName(appointment.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date and time info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PetCareTheme.primaryBeige.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PetCareTheme.primaryBeige.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: PetCareTheme.primaryBrown,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(appointment.appointmentDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: PetCareTheme.primaryBrown,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    appointment.timeSlot,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            
            // Reason if available
            if (appointment.reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PetCareTheme.lightBrown.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PetCareTheme.lightBrown.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: PetCareTheme.lightBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appointment.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons for upcoming appointments
            if (isUpcoming && appointment.status == AppointmentStatus.scheduled) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rescheduleAppointment(appointment),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PetCareTheme.primaryBrown,
                        side: BorderSide(
                          color: PetCareTheme.primaryBrown.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(
                          color: Colors.red[300]!,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return PetCareTheme.accentGold;
      case AppointmentStatus.confirmed:
        return PetCareTheme.softGreen;
      case AppointmentStatus.inProgress:
        return PetCareTheme.warmRed;
      case AppointmentStatus.completed:
        return PetCareTheme.softGreen.withValues(alpha: 0.8);
      case AppointmentStatus.cancelled:
        return PetCareTheme.warmRed.withValues(alpha: 0.7);
      case AppointmentStatus.noShow:
        return PetCareTheme.darkBrown;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule_rounded;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_rounded;
      case AppointmentStatus.inProgress:
        return Icons.hourglass_bottom_rounded;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_rounded;
      case AppointmentStatus.noShow:
        return Icons.person_off_rounded;
    }
  }

  String _getStatusName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  String _getAppointmentTypeName(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return 'Regular Checkup';
      case AppointmentType.vaccination:
        return 'Vaccination';
      case AppointmentType.surgery:
        return 'Surgery';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.grooming:
        return 'Grooming';
      case AppointmentType.consultation:
        return 'Consultation';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    // TODO: Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reschedule feature coming soon!'),
        backgroundColor: PetCareTheme.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      final success = await appointmentService.cancelAppointment(appointment.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment cancelled successfully'),
            backgroundColor: PetCareTheme.softGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to cancel appointment'),
            backgroundColor: PetCareTheme.warmRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
