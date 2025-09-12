import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../models/health_record_model.dart';
import '../../services/appointment_service.dart';
import '../../services/pet_service.dart';
import '../../services/health_record_service.dart';
import '../../services/auth_service.dart';

class VetAppointmentCompletionScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const VetAppointmentCompletionScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<VetAppointmentCompletionScreen> createState() => _VetAppointmentCompletionScreenState();
}

class _VetAppointmentCompletionScreenState extends State<VetAppointmentCompletionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Medical details controllers
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  
  // Health record controllers
  final _recordTitleController = TextEditingController();
  final _recordDescriptionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _recordNotesController = TextEditingController();
  
  PetModel? _pet;
  List<HealthRecordModel> _petHealthRecords = [];
  HealthRecordType _selectedRecordType = HealthRecordType.checkup;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _createHealthRecord = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPetData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _costController.dispose();
    _recordTitleController.dispose();
    _recordDescriptionController.dispose();
    _medicationController.dispose();
    _dosageController.dispose();
    _recordNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadPetData() async {
    setState(() => _isLoading = true);

    try {
      final petService = Provider.of<PetService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);

      // Load pet information
      final pet = await petService.getPetById(widget.appointment.petId);
      
      // Load pet's health records
      final healthRecords = await healthService.getHealthRecordsByPetId(widget.appointment.petId);

      setState(() {
        _pet = pet;
        _petHealthRecords = healthRecords;
        _isLoading = false;
      });

      // Pre-fill some fields based on appointment type
      _prefillFields();
    } catch (e) {
      debugPrint('Error loading pet data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _prefillFields() {
    // Pre-fill record title based on appointment type
    _recordTitleController.text = '${widget.appointment.type.toString().split('.').last} - ${DateFormat('MMM dd, yyyy').format(widget.appointment.appointmentDate)}';
    
    // Pre-fill record description with appointment reason
    _recordDescriptionController.text = widget.appointment.reason;
    
    // Set record type based on appointment type
    switch (widget.appointment.type) {
      case AppointmentType.vaccination:
        _selectedRecordType = HealthRecordType.vaccination;
        break;
      case AppointmentType.surgery:
        _selectedRecordType = HealthRecordType.surgery;
        break;
      case AppointmentType.checkup:
        _selectedRecordType = HealthRecordType.checkup;
        break;
      default:
        _selectedRecordType = HealthRecordType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Appointment'),
        actions: [
          TextButton(
            onPressed: _saveAppointment,
            child: const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Medical Details', icon: Icon(Icons.medical_services)),
            Tab(text: 'Health Record', icon: Icon(Icons.health_and_safety)),
            Tab(text: 'Pet History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedicalDetailsTab(),
                _buildHealthRecordTab(),
                _buildPetHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildMedicalDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Pet', _pet?.name ?? 'Unknown'),
                    _buildInfoRow('Date', DateFormat('EEEE, MMMM dd, yyyy').format(widget.appointment.appointmentDate)),
                    _buildInfoRow('Time', widget.appointment.timeSlot),
                    _buildInfoRow('Type', widget.appointment.type.toString().split('.').last),
                    _buildInfoRow('Reason', widget.appointment.reason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Medical Details Section
            Text(
              'Medical Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis *',
                hintText: 'Enter the diagnosis...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a diagnosis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _treatmentController,
              decoration: const InputDecoration(
                labelText: 'Treatment',
                hintText: 'Describe the treatment provided...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _prescriptionController,
              decoration: const InputDecoration(
                labelText: 'Prescription',
                hintText: 'Enter prescribed medications...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any additional observations or notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost (\$)',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle for creating health record
          Card(
            child: SwitchListTile(
              title: const Text('Create Health Record'),
              subtitle: const Text('Add this appointment to the pet\'s health records'),
              value: _createHealthRecord,
              onChanged: (value) {
                setState(() => _createHealthRecord = value);
              },
            ),
          ),
          const SizedBox(height: 16),

          if (_createHealthRecord) ...[
            Text(
              'Health Record Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<HealthRecordType>(
              value: _selectedRecordType,
              decoration: const InputDecoration(
                labelText: 'Record Type',
                border: OutlineInputBorder(),
              ),
              items: HealthRecordType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRecordType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _recordTitleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: _createHealthRecord ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              } : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _recordDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: _createHealthRecord ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              } : null,
            ),
            const SizedBox(height: 16),

            if (_selectedRecordType == HealthRecordType.medication || 
                _selectedRecordType == HealthRecordType.vaccination) ...[
              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication/Vaccine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _recordNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Next due date
            ListTile(
              title: const Text('Next Due Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_nextDueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectNextDueDate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet Health History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_petHealthRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No health records found for this pet'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _petHealthRecords.length,
              itemBuilder: (context, index) {
                final record = _petHealthRecords[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRecordTypeColor(record.type).withOpacity(0.1),
                      child: Icon(
                        _getRecordTypeIcon(record.type),
                        color: _getRecordTypeColor(record.type),
                      ),
                    ),
                    title: Text(record.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(record.recordDate)),
                        if (record.medication != null)
                          Text('Medication: ${record.medication}'),
                      ],
                    ),
                    onTap: () => _showRecordDetails(record),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _selectNextDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() => _nextDueDate = date);
    }
  }

  void _showRecordDetails(HealthRecordModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${record.type.toString().split('.').last}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(record.recordDate)}'),
              if (record.nextDueDate != null) ...[
                const SizedBox(height: 8),
                Text('Next Due: ${DateFormat('MMM dd, yyyy').format(record.nextDueDate!)}'),
              ],
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(record.description),
              if (record.medication != null) ...[
                const SizedBox(height: 8),
                const Text('Medication:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.medication!),
              ],
              if (record.dosage != null) ...[
                const SizedBox(height: 8),
                const Text('Dosage:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.dosage!),
              ],
              if (record.notes != null) ...[
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.notes!),
              ],
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
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Complete the appointment
      final cost = _costController.text.isNotEmpty ? double.tryParse(_costController.text) : null;
      
      await appointmentService.completeAppointment(
        appointmentId: widget.appointment.id,
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim().isNotEmpty ? _treatmentController.text.trim() : null,
        prescription: _prescriptionController.text.trim().isNotEmpty ? _prescriptionController.text.trim() : null,
        cost: cost,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Create health record if requested
      if (_createHealthRecord && authService.currentUser != null) {
        final healthRecord = HealthRecordModel(
          id: '', // Will be set by Firestore
          petId: widget.appointment.petId,
          veterinarianId: authService.currentUser!.uid,
          type: _selectedRecordType,
          title: _recordTitleController.text.trim(),
          description: _recordDescriptionController.text.trim(),
          recordDate: widget.appointment.appointmentDate,
          nextDueDate: _nextDueDate,
          medication: _medicationController.text.trim().isNotEmpty ? _medicationController.text.trim() : null,
          dosage: _dosageController.text.trim().isNotEmpty ? _dosageController.text.trim() : null,
          notes: _recordNotesController.text.trim().isNotEmpty ? _recordNotesController.text.trim() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await healthService.addHealthRecord(healthRecord);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error completing appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
