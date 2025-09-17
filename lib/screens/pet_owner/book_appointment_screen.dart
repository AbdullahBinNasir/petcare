import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/user_service.dart';
import '../../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  List<PetModel> _pets = [];
  List<UserModel> _veterinarians = [];
  List<String> _availableSlots = [];

  PetModel? _selectedPet;
  UserModel? _selectedVeterinarian;
  AppointmentType _selectedType = AppointmentType.checkup;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  bool _isLoading = false;
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final petService = Provider.of<PetService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.currentUser != null) {
      final pets = await petService.getPetsByOwnerId(authService.currentUser!.uid);
      final vets = await userService.getVeterinarians();

      setState(() {
        _pets = pets;
        _veterinarians = vets;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedVeterinarian == null) return;

    setState(() => _isLoadingSlots = true);

    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final slots = await appointmentService.getAvailableTimeSlots(
      _selectedVeterinarian!.id,
      _selectedDate,
    );

    setState(() {
      _availableSlots = slots;
      _selectedTimeSlot = null;
      _isLoadingSlots = false;
    });
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPet == null || _selectedVeterinarian == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      print('Creating appointment with:');
      print('Pet: ${_selectedPet!.name} (${_selectedPet!.id})');
      print('Vet: ${_selectedVeterinarian!.fullName} (${_selectedVeterinarian!.id})');
      print('Date: $_selectedDate');
      print('Time: $_selectedTimeSlot');
      print('Type: $_selectedType');
      
      final appointment = AppointmentModel(
        id: '', // Firestore will auto-generate
        petOwnerId: authService.currentUser!.uid,
        petId: _selectedPet!.id,
        veterinarianId: _selectedVeterinarian!.id,
        appointmentDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        type: _selectedType,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Appointment model created successfully');
      
      final docId = await appointmentService.bookAppointment(appointment);

      if (docId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment booked successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to book appointment. Please try again.')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error in _bookAppointment: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAppointmentTypeName(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return 'Checkup';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Selection
                    DropdownButtonFormField<PetModel>(
                      value: _selectedPet,
                      decoration: const InputDecoration(labelText: 'Select Pet'),
                      items: _pets.map((pet) => DropdownMenuItem(value: pet, child: Text(pet.name))).toList(),
                      onChanged: (val) => setState(() => _selectedPet = val),
                      validator: (val) => val == null ? 'Select a pet' : null,
                    ),
                    const SizedBox(height: 16),
                    // Vet Selection
                    DropdownButtonFormField<UserModel>(
                      value: _selectedVeterinarian,
                      decoration: const InputDecoration(labelText: 'Select Veterinarian'),
                      items: _veterinarians.map((vet) => DropdownMenuItem(value: vet, child: Text(vet.fullName))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedVeterinarian = val);
                        _loadAvailableSlots();
                      },
                      validator: (val) => val == null ? 'Select a vet' : null,
                    ),
                    const SizedBox(height: 16),
                    // Appointment Type
                    DropdownButtonFormField<AppointmentType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Appointment Type'),
                      items: AppointmentType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(_getAppointmentTypeName(t))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    Row(
                      children: [
                        const Text('Select Date: '),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                              _loadAvailableSlots();
                            }
                          },
                          child: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Time slots
                    _isLoadingSlots
                        ? const CircularProgressIndicator()
                        : Wrap(
                            spacing: 8,
                            children: _availableSlots
                                .map((slot) => ChoiceChip(
                                      label: Text(slot),
                                      selected: _selectedTimeSlot == slot,
                                      onSelected: (_) => setState(() => _selectedTimeSlot = slot),
                                    ))
                                .toList(),
                          ),
                    const SizedBox(height: 16),
                    // Reason & notes
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      validator: (val) => val == null || val.isEmpty ? 'Enter reason' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        child: const Text('Book Appointment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
