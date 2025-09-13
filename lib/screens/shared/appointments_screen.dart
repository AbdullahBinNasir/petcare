import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'appointment_details_screen.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAppointments() {
    // Appointments will be loaded via FutureBuilder
  }

  List<AppointmentModel> _getAppointmentsForDay(DateTime day) {
    // This will be handled by FutureBuilder in the calendar view
    return [];
  }

  List<AppointmentModel> _getFilteredAppointments(List<AppointmentModel> appointments) {
    return appointments.where((appointment) {
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return appointment.reason.toLowerCase().contains(searchTerm) ||
               appointment.type.toString().toLowerCase().contains(searchTerm);
      }
      return true;
    }).toList();
  }

  Future<List<AppointmentModel>> _getUserAppointments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    final firebaseUser = authService.currentUser;
    
    if (currentUser != null && firebaseUser != null) {
      print('Getting appointments for user: ${currentUser.id}, role: ${currentUser.role}');
      print('Firebase UID: ${firebaseUser.uid}');
      
      // Check user role and fetch appropriate appointments
      if (currentUser.role == UserRole.veterinarian) {
        print('Fetching appointments for veterinarian using Firebase UID');
        // Use Firebase Auth UID for veterinarian appointments
        return await appointmentService.getAppointmentsByVeterinarian(firebaseUser.uid);
      } else if (currentUser.role == UserRole.petOwner) {
        print('Fetching appointments for pet owner using Firebase UID');
        // Use Firebase Auth UID for pet owner appointments too
        return await appointmentService.getAppointmentsByPetOwner(firebaseUser.uid);
      } else {
        print('Unknown user role: ${currentUser.role}');
      }
    } else {
      print('No current user found');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildUpcomingView(),
          _buildHistoryView(),
        ],
      ),
      floatingActionButton: Consumer<AuthService>(
        builder: (context, authService, child) {
          final currentUser = authService.currentUserModel;
          // Only show FAB for pet owners
          if (currentUser?.role == UserRole.petOwner) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookAppointmentScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        return Column(
          children: [
            TableCalendar<AppointmentModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getAppointmentsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: FutureBuilder<List<AppointmentModel>>(
                future: _getUserAppointments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData) {
                    return const Center(child: Text('No appointments found'));
                  }
                  
                  final dayAppointments = snapshot.data!.where((appointment) {
                    return isSameDay(appointment.appointmentDate, _selectedDay!);
                  }).toList();
                  
                  return _buildAppointmentsList(dayAppointments);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingView() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        return FutureBuilder<List<AppointmentModel>>(
          future: _getUserAppointments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData) {
              return const Center(child: Text('No appointments found'));
            }
            
            final allAppointments = snapshot.data!;
            print('Total appointments found: ${allAppointments.length}');
            
            final now = DateTime.now();
            print('Current time: $now');
            
            final upcomingAppointments = allAppointments.where((apt) {
              final isUpcoming = apt.isUpcoming; // uses status and date
              print('Appointment: ${apt.reason} - Date: ${apt.appointmentDate} - Status: ${apt.status} - Is upcoming: $isUpcoming');
              return isUpcoming;
            }).toList();
            
            print('Upcoming appointments found: ${upcomingAppointments.length}');
            upcomingAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

            final filteredAppointments = _getFilteredAppointments(upcomingAppointments);

            if (filteredAppointments.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No upcoming appointments',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final appointment = filteredAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryView() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        return FutureBuilder<List<AppointmentModel>>(
          future: _getUserAppointments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData) {
              return const Center(child: Text('No appointments found'));
            }
            
            final allAppointments = snapshot.data!;
            print('Total appointments for history: ${allAppointments.length}');
            
            final now = DateTime.now();
            print('Current time for history: $now');
            
            final pastAppointments = allAppointments.where((apt) {
              final isPast = apt.isPast; // past if date passed or completed
              print('History - Appointment: ${apt.reason} - Date: ${apt.appointmentDate} - Status: ${apt.status} - Is past: $isPast');
              return isPast;
            }).toList();
            
            print('Past appointments found: ${pastAppointments.length}');
            pastAppointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

            final filteredPastAppointments = _getFilteredAppointments(pastAppointments);

            if (filteredPastAppointments.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No appointment history',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredPastAppointments.length,
              itemBuilder: (context, index) {
                final appointment = filteredPastAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text(
          'No appointments for this day',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(appointment: appointment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(appointment.appointmentDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    appointment.timeSlot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeText(appointment.type),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appointment.reason,
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: 4),
                Text(
                  appointment.notes!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.teal;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
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

  String _getTypeText(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return 'Check-up';
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
}
