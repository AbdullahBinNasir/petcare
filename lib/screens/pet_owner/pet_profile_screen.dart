import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_service.dart';
import '../../services/appointment_service.dart';
import '../../services/health_record_service.dart';
import '../../models/pet_model.dart';
import '../../models/appointment_model.dart';
import '../../models/health_record_model.dart';
import 'edit_pet_screen.dart';
import 'health_records_screen.dart';
import 'add_health_record_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final PetModel pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _appointments = [];
  List<HealthRecordModel> _healthRecords = [];
  List<HealthRecordModel> _dueRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    final appointments = await appointmentService.getAppointmentsByPet(widget.pet.id);
    final healthRecords = await healthService.getHealthRecordsByPetId(widget.pet.id);
    final dueRecords = await healthService.getDueHealthRecords(widget.pet.id);

    setState(() {
      _appointments = appointments;
      _healthRecords = healthRecords;
      _dueRecords = dueRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPetScreen(pet: widget.pet),
                ),
              ).then((_) {
                // Refresh the screen if pet was updated
                Navigator.pop(context);
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Pet', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.pets)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildHealthTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Gallery
          if (widget.pet.photoUrls.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: widget.pet.photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.pet.photoUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No photos added',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Basic Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', widget.pet.name, Icons.pets),
                  _buildInfoRow('Species', _getSpeciesName(widget.pet.species), Icons.category),
                  _buildInfoRow('Breed', widget.pet.breed, Icons.info_outline),
                  _buildInfoRow('Gender', _getGenderName(widget.pet.gender), Icons.wc),
                  if (widget.pet.dateOfBirth != null)
                    _buildInfoRow('Age', widget.pet.ageString, Icons.cake),
                  if (widget.pet.weight != null)
                    _buildInfoRow('Weight', '${widget.pet.weight} kg', Icons.monitor_weight),
                  if (widget.pet.color != null)
                    _buildInfoRow('Color', widget.pet.color!, Icons.palette),
                  if (widget.pet.microchipId != null)
                    _buildInfoRow('Microchip ID', widget.pet.microchipId!, Icons.qr_code),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Health Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getHealthStatusColor(widget.pet.healthStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          color: _getHealthStatusColor(widget.pet.healthStatus),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getHealthStatusName(widget.pet.healthStatus),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getHealthStatusColor(widget.pet.healthStatus),
                              ),
                            ),
                            if (widget.pet.medicalNotes != null)
                              Text(
                                widget.pet.medicalNotes!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: _getHealthStatusColor(widget.pet.healthStatus),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Health Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getHealthStatusColor(widget.pet.healthStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getHealthStatusText(widget.pet.healthStatus),
                      style: TextStyle(
                        color: _getHealthStatusColor(widget.pet.healthStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Due Records Alert
          if (_dueRecords.isNotEmpty) ...[
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Due Records (${_dueRecords.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._dueRecords.take(3).map((record) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${record.title} - Due: ${_formatDate(record.nextDueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )),
                    if (_dueRecords.length > 3)
                      Text(
                        'And ${_dueRecords.length - 3} more...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Medical Notes
          if (widget.pet.medicalNotes != null && widget.pet.medicalNotes!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.note_alt),
                        const SizedBox(width: 8),
                        Text(
                          'Medical Notes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.pet.medicalNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Health Records Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services),
                      const SizedBox(width: 8),
                      Text(
                        'Health Records',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HealthRecordsScreen(petId: widget.pet.id),
                            ),
                          );
                          if (result == true) {
                            _loadAppointments();
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_healthRecords.isEmpty)
                    Column(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No health records yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddHealthRecordScreen(petId: widget.pet.id),
                              ),
                            );
                            if (result == true) {
                              _loadAppointments();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Record'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ..._healthRecords.take(3).map((record) => _buildHealthRecordTile(record)),
                        if (_healthRecords.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'And ${_healthRecords.length - 3} more records...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddHealthRecordScreen(petId: widget.pet.id),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadAppointments();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Record'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordTile(HealthRecordModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getRecordTypeColor(record.type).withOpacity(0.1),
            child: Icon(
              _getRecordTypeIcon(record.type),
              size: 16,
              color: _getRecordTypeColor(record.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_getRecordTypeName(record.type)} • ${_formatDate(record.recordDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (record.nextDueDate != null && record.isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: record.isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.isOverdue ? 'Overdue' : 'Due',
                style: TextStyle(
                  color: record.isOverdue ? Colors.red : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                if (_appointments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No appointments yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Book your first appointment to see history here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._appointments.map((appointment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAppointmentStatusColor(appointment.status),
                          child: Icon(
                            _getAppointmentTypeIcon(appointment.type),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(_getAppointmentTypeName(appointment.type)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year} at ${appointment.timeSlot}'),
                            if (appointment.reason.isNotEmpty)
                              Text('Reason: ${appointment.reason}'),
                            if (appointment.diagnosis != null && appointment.diagnosis!.isNotEmpty)
                              Text('Diagnosis: ${appointment.diagnosis}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getAppointmentStatusName(appointment.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getAppointmentStatusColor(appointment.status),
                            ),
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
              ],
            ),
          );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final petService = Provider.of<PetService>(context, listen: false);
              final success = await petService.deletePet(widget.pet.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pet deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete pet'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getSpeciesName(PetSpecies species) {
    return species.toString().split('.').last.toUpperCase();
  }

  String _getGenderName(PetGender gender) {
    return gender.toString().split('.').last.toUpperCase();
  }

  String _getHealthStatusName(HealthStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  String _getAppointmentTypeName(AppointmentType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  String _getAppointmentStatusName(AppointmentStatus status) {
    return status.toString().split('.').last.toUpperCase();
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
        return Colors.brown;
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
        return Icons.note_alt;
    }
  }

  String _getRecordTypeName(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.allergy:
        return 'Allergy';
      case HealthRecordType.injury:
        return 'Injury';
      case HealthRecordType.other:
        return 'Other';
    }
  }

  String _getHealthStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.sick:
        return 'Sick';
      case HealthStatus.recovering:
        return 'Recovering';
      case HealthStatus.critical:
        return 'Critical';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
