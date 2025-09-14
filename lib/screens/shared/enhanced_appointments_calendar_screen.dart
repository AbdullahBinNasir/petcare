import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../shared/appointment_details_screen.dart';

class EnhancedAppointmentsCalendarScreen extends StatefulWidget {
  const EnhancedAppointmentsCalendarScreen({super.key});

  @override
  State<EnhancedAppointmentsCalendarScreen> createState() => _EnhancedAppointmentsCalendarScreenState();
}

class _EnhancedAppointmentsCalendarScreenState extends State<EnhancedAppointmentsCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<AppointmentModel>> _appointmentsByDate = {};
  bool _isLoading = true;
  String _viewFilter = 'all'; // all, upcoming, today, completed

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final user = authService.currentUserModel;
    
    if (user != null) {
      // Load appointments for the visible month range
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final appointments = await appointmentService.getAppointmentsByDateRange(
        startDate: startOfMonth,
        endDate: endOfMonth,
        userId: user.id,
        isVet: user.role == UserRole.veterinarian,
      );
      
      setState(() {
        _appointmentsByDate = appointments;
        _isLoading = false;
      });
    }
  }

  List<AppointmentModel> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    List<AppointmentModel> events = _appointmentsByDate[dayKey] ?? [];
    
    // Apply filter
    switch (_viewFilter) {
      case 'upcoming':
        events = events.where((e) => e.isUpcoming).toList();
        break;
      case 'today':
        final today = DateTime.now();
        events = events.where((e) => 
          e.appointmentDate.year == today.year &&
          e.appointmentDate.month == today.month &&
          e.appointmentDate.day == today.day
        ).toList();
        break;
      case 'completed':
        events = events.where((e) => e.status == AppointmentStatus.completed).toList();
        break;
    }
    
    return events;
  }

  Color _getEventColor(AppointmentModel appointment) {
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.red.shade300;
      default:
        return Colors.blue;
    }
  }

  IconData _getEventIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return Icons.medical_services;
      case AppointmentType.vaccination:
        return Icons.vaccines;
      case AppointmentType.surgery:
        return Icons.local_hospital;
      case AppointmentType.emergency:
        return Icons.emergency;
      case AppointmentType.grooming:
        return Icons.pets;
      case AppointmentType.consultation:
        return Icons.chat;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Calendar'),
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() => _viewFilter = filter);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Appointments')),
              const PopupMenuItem(value: 'upcoming', child: Text('Upcoming Only')),
              const PopupMenuItem(value: 'today', child: Text("Today's Appointments")),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
          // Statistics button (for vets and admins)
          if (user?.role == UserRole.veterinarian || user?.role == UserRole.shelterAdmin)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => _showStatistics(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar widget
                TableCalendar<AppointmentModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                    _loadAppointments();
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((event) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _getEventColor(event as AppointmentModel),
                              shape: BoxShape.circle,
                            ),
                          )).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Day's appointments
                Expanded(
                  child: _selectedDay == null
                      ? const Center(child: Text('Select a day to view appointments'))
                      : _buildDayAppointments(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookAppointmentDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Book New Appointment',
      ),
    );
  }

  Widget _buildDayAppointments() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No appointments for ${DateFormat('MMMM dd, yyyy').format(_selectedDay!)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final appointment = events[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEventColor(appointment).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getEventIcon(appointment.type),
            color: _getEventColor(appointment),
          ),
        ),
        title: Text(
          appointment.reason,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment.timeSlot} • ${appointment.type.toString().split('.').last}'),
            if (appointment.notes?.isNotEmpty == true)
              Text(
                appointment.notes!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEventColor(appointment).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appointment.status.toString().split('.').last,
                style: TextStyle(
                  color: _getEventColor(appointment),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(appointment: appointment),
            ),
          );
        },
      ),
    );
  }

  void _showBookAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: const Text('Would you like to book a new appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to booking screen
              // Navigator.pushNamed(context, '/book-appointment');
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() async {
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading statistics...'),
          ],
        ),
      ),
    );

    try {
      final stats = await appointmentService.getBookingStatistics();
      Navigator.pop(context); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Statistics'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Bookings', '${stats['totalBookings'] ?? 0}'),
                _buildStatRow('Completed', '${stats['completedBookings'] ?? 0}'),
                _buildStatRow('Upcoming', '${stats['upcomingBookings'] ?? 0}'),
                _buildStatRow('Cancelled', '${stats['cancelledBookings'] ?? 0}'),
                const Divider(),
                _buildStatRow('Completion Rate', '${stats['completionRate'] ?? 0}%'),
                _buildStatRow('Cancellation Rate', '${stats['cancellationRate'] ?? 0}%'),
                const Divider(),
                _buildStatRow('Total Revenue', '\$${stats['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
                _buildStatRow('Average Revenue', '\$${stats['averageRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
