import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/user_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  AppointmentType _selectedType = AppointmentType.checkup;
  PetModel? _selectedPet;
  String? _selectedPetId;
  UserModel? _selectedVet;
  String? _selectedVetId;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
    '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Data will be loaded when needed in the UI widgets
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPetSelection(),
              const SizedBox(height: 16),
              _buildVetSelection(),
              const SizedBox(height: 16),
              _buildAppointmentTypeSelection(),
              const SizedBox(height: 16),
              _buildDateSelection(),
              const SizedBox(height: 16),
              _buildTimeSlotSelection(),
              const SizedBox(height: 16),
              _buildReasonField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Pet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<PetModel>>(
              future: _getUserPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No pets available. Please add a pet first.');
                }
                
                return DropdownButtonFormField<String>(
                  value: _selectedPetId,
                  decoration: const InputDecoration(
                    labelText: 'Select Pet',
                    border: OutlineInputBorder(),
                  ),
                  items: snapshot.data!.map((pet) {
                    return DropdownMenuItem<String>(
                      value: pet.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: pet.photoUrls.isNotEmpty
                                ? NetworkImage(pet.photoUrls.first)
                                : null,
                            child: pet.photoUrls.isEmpty
                                ? const Icon(Icons.pets, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(pet.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (petId) {
                    setState(() {
                      _selectedPetId = petId;
                      _selectedPet = snapshot.data!.firstWhere((pet) => pet.id == petId);
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a pet';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<PetModel>> _getUserPets() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final petService = Provider.of<PetService>(context, listen: false);
    
    if (authService.currentUserModel != null) {
      return await petService.getPetsByOwnerId(authService.currentUserModel!.id);
    }
    return [];
  }

  Widget _buildVetSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Veterinarian',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<UserModel>>(
              future: Provider.of<UserService>(context, listen: false).getVeterinarians(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No veterinarians available');
                }
                
                return DropdownButtonFormField<String>(
                  value: _selectedVetId,
                  decoration: const InputDecoration(
                    labelText: 'Select Veterinarian',
                    border: OutlineInputBorder(),
                  ),
                  items: snapshot.data!.map((vet) {
                    return DropdownMenuItem<String>(
                      value: vet.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: vet.profileImageUrl != null
                                ? NetworkImage(vet.profileImageUrl!)
                                : null,
                            child: vet.profileImageUrl == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(vet.fullName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (vetId) {
                    setState(() {
                      _selectedVetId = vetId;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a veterinarian';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppointmentType>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: AppointmentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeText(type)),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _selectedTimeSlot = null; // Reset time slot when date changes
                });
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
              ),
              enabledDayPredicate: (day) {
                // Disable past dates and weekends for this example
                return day.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
                       day.weekday != DateTime.saturday &&
                       day.weekday != DateTime.sunday;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((timeSlot) {
                final isSelected = _selectedTimeSlot == timeSlot;
                return FilterChip(
                  label: Text(timeSlot),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeSlot = selected ? timeSlot : null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedTimeSlot == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a time slot',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Visit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Describe the reason for this appointment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason for the visit';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Any additional information or concerns',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  void _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedTimeSlot == null) {
      if (_selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      final appointment = AppointmentModel(
        id: '', // Will be set by Firestore
        petOwnerId: authService.currentUserModel!.id,
        petId: _selectedPet!.id,
        veterinarianId: _selectedVetId!,
        appointmentDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        type: _selectedType,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await appointmentService.bookAppointment(appointment);
      
      // Notifications are scheduled by the service after Firestore ID is assigned

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
