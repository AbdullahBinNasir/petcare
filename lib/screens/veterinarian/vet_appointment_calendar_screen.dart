import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/user_service.dart';
import '../shared/appointment_details_screen.dart';
import '../shared/appointments_screen.dart';
import 'vet_availability_management_screen.dart';

class VetAppointmentCalendarScreen extends StatefulWidget {
  const VetAppointmentCalendarScreen({super.key});

  @override
  State<VetAppointmentCalendarScreen> createState() => _VetAppointmentCalendarScreenState();
}

class _VetAppointmentCalendarScreenState extends State<VetAppointmentCalendarScreen> {
  late final ValueNotifier<List<AppointmentModel>> _selectedAppointments;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  
  bool _isLoading = false;
  Map<DateTime, List<AppointmentModel>> _appointments = {};
  Map<DateTime, List<AppointmentModel>> _availabilitySlots = {};
  Map<String, String> _petNames = {};
  Map<String, String> _ownerNames = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedAppointments = ValueNotifier(_getAppointmentsForDay(_selectedDay!));
    _loadAppointments();
  }

  @override
  void dispose() {
    _selectedAppointments.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      
      if (authService.currentUser == null) return;

      // Load appointments for the current month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      // Use the correct method that returns appointments directly
      final appointments = await appointmentService.getAppointmentsByVeterinarian(
        authService.currentUser!.uid,
      );
      
      debugPrint('VetCalendar: Loaded ${appointments.length} total appointments');
      
      // Filter appointments for the current month
      final filteredAppointments = appointments.where((appointment) {
        return appointment.appointmentDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
               appointment.appointmentDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
      
      debugPrint('VetCalendar: Filtered to ${filteredAppointments.length} appointments for current month');

      // If no appointments found for current month, show all appointments
      final appointmentsToShow = filteredAppointments.isNotEmpty ? filteredAppointments : appointments;
      debugPrint('VetCalendar: Showing ${appointmentsToShow.length} appointments');

      // Group appointments by date
      final groupedAppointments = <DateTime, List<AppointmentModel>>{};
      for (final appointment in appointmentsToShow) {
        final date = DateTime(
          appointment.appointmentDate.year,
          appointment.appointmentDate.month,
          appointment.appointmentDate.day,
        );
        
        if (groupedAppointments[date] == null) {
          groupedAppointments[date] = [];
        }
        groupedAppointments[date]!.add(appointment);
      }

      // Load pet and owner names
      await _loadPetAndOwnerNames(appointmentsToShow);

      setState(() {
        _appointments = groupedAppointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPetAndOwnerNames(List<AppointmentModel> appointments) async {
    try {
      debugPrint('VetCalendar: Loading names for ${appointments.length} appointments');
      
      final petService = Provider.of<PetService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      
      final petIds = appointments.map((a) => a.petId).toSet();
      final ownerIds = appointments.map((a) => a.petOwnerId).toSet();
      
      debugPrint('VetCalendar: Found ${petIds.length} unique pets and ${ownerIds.length} unique owners');
      
      // Load pet names
      for (final petId in petIds) {
        try {
          final pet = await petService.getPetById(petId);
          if (pet != null) {
            _petNames[petId] = pet.name;
            debugPrint('VetCalendar: Loaded pet name: ${pet.name}');
          } else {
            debugPrint('VetCalendar: Pet not found for ID: $petId');
          }
        } catch (e) {
          debugPrint('Error loading pet $petId: $e');
        }
      }
      
      // Load owner names
      for (final ownerId in ownerIds) {
        try {
          final owner = await userService.getUserById(ownerId);
          if (owner != null) {
            _ownerNames[ownerId] = owner.fullName;
            debugPrint('VetCalendar: Loaded owner name: ${owner.fullName}');
          } else {
            debugPrint('VetCalendar: Owner not found for ID: $ownerId');
          }
        } catch (e) {
          debugPrint('Error loading owner $ownerId: $e');
        }
      }
      
      debugPrint('VetCalendar: Loaded ${_petNames.length} pet names and ${_ownerNames.length} owner names');
    } catch (e) {
      debugPrint('Error loading pet and owner names: $e');
    }
  }

  List<AppointmentModel> _getAppointmentsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _appointments[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedAppointments.value = _getAppointmentsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedAppointments.value = _getAppointmentsForDayRange(start, end);
    } else if (start != null) {
      _selectedAppointments.value = _getAppointmentsForDay(start);
    } else {
      _selectedAppointments.value = [];
    }
  }

  List<AppointmentModel> _getAppointmentsForDayRange(DateTime start, DateTime end) {
    final appointments = <AppointmentModel>[];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      appointments.addAll(_getAppointmentsForDay(date));
    }
    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Calendar'),
        actions: [
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'availability',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Manage Availability'),
                ),
              ),
              const PopupMenuItem(
                value: 'view_all',
                child: ListTile(
                  leading: Icon(Icons.list),
                  title: Text('View All Appointments'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<AppointmentModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getAppointmentsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    rangeSelectionMode: _rangeSelectionMode,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    onDaySelected: _onDaySelected,
                    onRangeSelected: _onRangeSelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadAppointments();
                    },
                  ),
                ),
                
                // Selected day appointments
                Expanded(
                  child: ValueListenableBuilder<List<AppointmentModel>>(
                    valueListenable: _selectedAppointments,
                    builder: (context, appointments, _) {
                      if (appointments.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return _buildAppointmentsList(appointments);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAvailabilityDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Availability'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedDay != null
                ? 'No appointments on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'
                : 'No appointments in selected range',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add availability slots',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(appointment.status),
              child: Icon(
                _getStatusIcon(appointment.status),
                color: Colors.white,
              ),
            ),
            title: Text(
              _petNames[appointment.petId] ?? 'Pet ID: ${appointment.petId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner: ${_ownerNames[appointment.petOwnerId] ?? 'Unknown Owner'}'),
                Text('Time: ${DateFormat('HH:mm').format(appointment.appointmentDate)}'),
                Text('Type: ${appointment.type.toString().split('.').last}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appointment.status == AppointmentStatus.scheduled)
                  IconButton(
                    onPressed: () => _confirmAppointment(appointment),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Confirm',
                  ),
                if (appointment.status == AppointmentStatus.scheduled ||
                    appointment.status == AppointmentStatus.confirmed)
                  IconButton(
                    onPressed: () => _rescheduleAppointment(appointment),
                    icon: const Icon(Icons.schedule, color: Colors.orange),
                    tooltip: 'Reschedule',
                  ),
                IconButton(
                  onPressed: () => _viewAppointmentDetails(appointment),
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                ),
              ],
            ),
            onTap: () => _viewAppointmentDetails(appointment),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.red.shade800;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.play_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'availability':
        _showAvailabilityDialog();
        break;
      case 'view_all':
        _showAllAppointments();
        break;
    }
  }

  void _showAvailabilityDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VetAvailabilityManagementScreen(),
      ),
    ).then((_) => _loadAppointments()); // Refresh calendar when returning
  }

  void _showAllAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentsScreen(),
      ),
    );
  }

  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      await appointmentService.confirmAppointment(appointment.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    DateTime selectedDate = appointment.appointmentDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appointment.appointmentDate);
    String selectedTimeSlot = appointment.timeSlot;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reschedule Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet: ${_petNames[appointment.petId] ?? 'Unknown Pet'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Owner: ${_ownerNames[appointment.petOwnerId] ?? 'Unknown Owner'}'),
                const SizedBox(height: 16),
                
                // Date Selection
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'New Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time Selection
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                        selectedTimeSlot = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'New Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(selectedTime.format(context)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reason for Rescheduling
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for Rescheduling (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason for rescheduling...',
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    // Store the reason if needed
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _confirmReschedule(appointment, selectedDate, selectedTimeSlot),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReschedule(AppointmentModel appointment, DateTime newDate, String newTimeSlot) async {
    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      
      // Create new appointment date with the selected time
      final newAppointmentDate = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        int.parse(newTimeSlot.split(':')[0]),
        int.parse(newTimeSlot.split(':')[1]),
      );
      
      // Update the appointment
      final updatedAppointment = appointment.copyWith(
        appointmentDate: newAppointmentDate,
        timeSlot: newTimeSlot,
        updatedAt: DateTime.now(),
      );
      
      final success = await appointmentService.updateAppointment(updatedAppointment);
      
      if (success) {
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment rescheduled to ${DateFormat('MMM dd, yyyy').format(newDate)} at $newTimeSlot'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAppointments(); // Refresh the calendar
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reschedule appointment. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAppointmentDetails(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(appointment: appointment),
      ),
    );
  }
}
