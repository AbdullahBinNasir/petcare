import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/health_record_model.dart';
import '../../services/health_record_service.dart';
import '../../services/auth_service.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String petId;
  final HealthRecordModel? existingRecord;

  const AddHealthRecordScreen({
    super.key,
    required this.petId,
    this.existingRecord,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  HealthRecordType _selectedType = HealthRecordType.checkup;
  DateTime _recordDate = DateTime.now();
  DateTime? _nextDueDate;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingRecord != null;
    
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final record = widget.existingRecord!;
    _titleController.text = record.title;
    _descriptionController.text = record.description;
    _medicationController.text = record.medication ?? '';
    _dosageController.text = record.dosage ?? '';
    _notesController.text = record.notes ?? '';
    _selectedType = record.type;
    _recordDate = record.recordDate;
    _nextDueDate = record.nextDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _medicationController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Health Record' : 'Add Health Record'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteRecord,
              icon: const Icon(Icons.delete),
              color: Colors.red,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Record Type
              Text(
                'Record Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HealthRecordType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: HealthRecordType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getRecordTypeIcon(type),
                          size: 20,
                          color: _getRecordTypeColor(type),
                        ),
                        const SizedBox(width: 12),
                        Text(_getRecordTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Record Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Annual Vaccination, Rabies Shot',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Detailed description of the record',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Dates
              Text(
                'Dates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Record Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Record Date'),
                subtitle: Text(_formatDate(_recordDate)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context, true),
              ),
              const Divider(),

              // Next Due Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Next Due Date (Optional)'),
                subtitle: Text(_nextDueDate != null 
                    ? _formatDate(_nextDueDate!) 
                    : 'Not set'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_nextDueDate != null)
                      IconButton(
                        onPressed: () => setState(() => _nextDueDate = null),
                        icon: const Icon(Icons.clear),
                        color: Colors.red,
                      ),
                    const Icon(Icons.edit),
                  ],
                ),
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 24),

              // Medication Section (if applicable)
              if (_selectedType == HealthRecordType.medication || 
                  _selectedType == HealthRecordType.vaccination) ...[
                Text(
                  'Medication Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medicationController,
                  decoration: InputDecoration(
                    labelText: _selectedType == HealthRecordType.vaccination 
                        ? 'Vaccine Name' 
                        : 'Medication Name',
                    prefixIcon: const Icon(Icons.medication),
                    border: const OutlineInputBorder(),
                    hintText: _selectedType == HealthRecordType.vaccination 
                        ? 'e.g., Rabies, DHPP' 
                        : 'e.g., Antibiotics, Pain Relief',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage/Amount',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 1ml, 250mg twice daily',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Additional Notes
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Any additional notes or observations',
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isEditing ? 'Update Record' : 'Save Record',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isRecordDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isRecordDate ? _recordDate : (_nextDueDate ?? DateTime.now()),
      firstDate: isRecordDate ? DateTime(2000) : DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isRecordDate) {
          _recordDate = picked;
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final healthService = Provider.of<HealthRecordService>(context, listen: false);

        final record = HealthRecordModel(
          id: _isEditing ? widget.existingRecord!.id : '',
          petId: widget.petId,
          veterinarianId: authService.currentUser?.uid ?? '',
          type: _selectedType,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          recordDate: _recordDate,
          nextDueDate: _nextDueDate,
          medication: _medicationController.text.trim().isNotEmpty 
              ? _medicationController.text.trim() 
              : null,
          dosage: _dosageController.text.trim().isNotEmpty 
              ? _dosageController.text.trim() 
              : null,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
          createdAt: _isEditing ? widget.existingRecord!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool success;
        if (_isEditing) {
          success = await healthService.updateHealthRecord(record);
        } else {
          final recordId = await healthService.addHealthRecord(record);
          success = recordId != null;
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                  ? 'Health record updated successfully!' 
                  : 'Health record added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save health record');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRecord() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Health Record'),
        content: const Text('Are you sure you want to delete this health record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final healthService = Provider.of<HealthRecordService>(context, listen: false);
        final success = await healthService.deleteHealthRecord(widget.existingRecord!.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health record deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to delete health record');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
