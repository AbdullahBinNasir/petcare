import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../shared/add_health_record_screen.dart';

class VetHealthRecordsScreen extends StatefulWidget {
  const VetHealthRecordsScreen({super.key});

  @override
  State<VetHealthRecordsScreen> createState() => _VetHealthRecordsScreenState();
}

class _VetHealthRecordsScreenState extends State<VetHealthRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _recentRecords = [];
  List<HealthRecordModel> _dueRecords = [];
  List<HealthRecordModel> _overdueRecords = [];
  Map<String, PetModel> _pets = {};
  PetModel? _selectedPet;
  bool _isLoading = true;
  String _searchQuery = '';
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🏥 VetHealthRecordsScreen: Starting to load data...');
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      if (authService.currentUser == null) {
        print('❌ VetHealthRecordsScreen: No current user found');
        return;
      }

      print('👤 VetHealthRecordsScreen: Current user: ${authService.currentUser!.uid}');
      
      // Load all health records created by this veterinarian
      print('🏥 VetHealthRecordsScreen: Loading health records for vet ID: ${authService.currentUser!.uid}');
      final records = await healthService.getHealthRecordsByVetId(authService.currentUser!.uid);
      print('📊 VetHealthRecordsScreen: Received ${records.length} health records from service');
      
      // Load pets from appointments (pets assigned to this veterinarian)
      final appointments = await appointmentService.getAppointmentsByVeterinarian(authService.currentUser!.uid);
      final appointmentPetIds = appointments.map((a) => a.petId).toSet();
      
      // Also include pets from existing health records
      final recordPetIds = records.map((r) => r.petId).toSet();
      final allPetIds = {...appointmentPetIds, ...recordPetIds};
      
      final pets = <String, PetModel>{};
      
      for (final petId in allPetIds) {
        final pet = await petService.getPetById(petId);
        if (pet != null) {
          pets[petId] = pet;
        }
      }

      setState(() {
        _allRecords = records;
        _pets = pets;
        _recentRecords = records.take(10).toList();
        _dueRecords = records.where((r) => r.isDue).toList();
        _overdueRecords = records.where((r) => r.isOverdue).toList();
        _isLoading = false;
      });
      
      print('✅ VetHealthRecordsScreen: Data loaded successfully');
      print('📊 VetHealthRecordsScreen: Final counts:');
      print('  - All records: ${_allRecords.length}');
      print('  - Recent records: ${_recentRecords.length}');
      print('  - Due records: ${_dueRecords.length}');
      print('  - Overdue records: ${_overdueRecords.length}');
      print('  - Pets loaded: ${_pets.length}');
    } catch (e) {
      print('❌ VetHealthRecordsScreen: Error loading health records: $e');
      debugPrint('Error loading health records: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Records', icon: Icon(Icons.list)),
            Tab(text: 'Recent', icon: Icon(Icons.schedule)),
            Tab(text: 'Due Soon', icon: Icon(Icons.warning)),
            Tab(text: 'Overdue', icon: Icon(Icons.error)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(_allRecords, 'No health records found'),
                _buildRecordsList(_recentRecords, 'No recent records'),
                _buildRecordsList(_dueRecords, 'No records due soon'),
                _buildRecordsList(_overdueRecords, 'No overdue records'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPetSelector,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _buildRecordsList(List<HealthRecordModel> records, String emptyMessage) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final pet = _pets[record.petId];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRecordTypeColor(record.type).withOpacity(0.1),
              child: Icon(
                _getRecordTypeIcon(record.type),
                color: _getRecordTypeColor(record.type),
              ),
            ),
            title: Text(
              record.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pet != null) Text('Pet: ${pet.name} (${pet.species.toString().split('.').last})'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(record.recordDate)}'),
                if (record.nextDueDate != null)
                  Text(
                    'Next Due: ${DateFormat('MMM dd, yyyy').format(record.nextDueDate!)}',
                    style: TextStyle(
                      color: record.isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleRecordAction(value, record),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showRecordDetails(record),
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Health Records'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, pet name, or description...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _filterRecords();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _filterRecords() {
    if (_searchQuery.isEmpty) {
      _loadData();
      return;
    }

    final filteredRecords = _allRecords.where((record) {
      final pet = _pets[record.petId];
      return record.title.toLowerCase().contains(_searchQuery) ||
             record.description.toLowerCase().contains(_searchQuery) ||
             (pet?.name.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    setState(() {
      _allRecords = filteredRecords;
    });
  }

  void _showPetSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Pet for Health Record'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _pets.isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No pets found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pets will appear here once they have appointments with you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets.values.elementAt(index);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pet.photoUrls.isNotEmpty
                              ? NetworkImage(pet.photoUrls.first)
                              : null,
                          child: pet.photoUrls.isEmpty
                              ? Icon(_getPetSpeciesIcon(pet.species))
                              : null,
                        ),
                        title: Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${pet.species.toString().split('.').last} • ${pet.breed}'),
                            if (pet.dateOfBirth != null)
                              Text(
                                'Age: ${_calculateAge(pet.dateOfBirth!)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.add_circle, color: Colors.blue),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAddRecord(pet.id);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddRecord(String petId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthRecordScreen(petId: petId),
      ),
    ).then((_) => _loadData());
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Medical Files'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a pet to upload files for:'),
            const SizedBox(height: 16),
            if (_pets.isEmpty)
              const Column(
                children: [
                  Icon(Icons.pets, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No pets found. Create health records for pets with appointments.'),
                ],
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets.values.elementAt(index);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: pet.photoUrls.isNotEmpty
                            ? NetworkImage(pet.photoUrls.first)
                            : null,
                        child: pet.photoUrls.isEmpty
                            ? Icon(_getPetSpeciesIcon(pet.species))
                            : null,
                      ),
                      title: Text(pet.name),
                      subtitle: Text('${pet.species.toString().split('.').last} • ${pet.breed}'),
                      trailing: const Icon(Icons.upload_file),
                      onTap: () {
                        Navigator.pop(context);
                        _showFileUploadOptions(pet.id);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFileUploadOptions(String petId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Medical Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(petId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(petId, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument(petId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(String petId, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadToStorage(petId, File(image.path), 'image');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadDocument(String petId) async {
    // For document upload, we'll use a simple file picker simulation
    // In a real app, you'd use file_picker package
    _showErrorSnackBar('Document upload feature coming soon');
  }

  Future<void> _uploadToStorage(String petId, File file, String type) async {
    try {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('medical_files/$petId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create a health record for the uploaded file
      final healthRecord = HealthRecordModel(
        id: '', // Will be set by Firestore
        petId: petId,
        veterinarianId: authService.currentUser!.uid,
        type: HealthRecordType.other,
        title: 'Uploaded $type - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
        description: 'Medical file uploaded by veterinarian',
        recordDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachmentUrls: [downloadUrl],
      );

      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      await healthService.addHealthRecord(healthRecord);

      _showSuccessSnackBar('File uploaded successfully');
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Error uploading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRecordDetails(HealthRecordModel record) {
    final pet = _pets[record.petId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pet != null) ...[
                Text('Pet: ${pet.name} (${pet.species.toString().split('.').last})'),
                const SizedBox(height: 8),
              ],
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

  void _handleRecordAction(String action, HealthRecordModel record) async {
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    switch (action) {
      case 'view':
        _showRecordDetails(record);
        break;
      case 'edit':
        // Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmation(record);
        if (confirmed) {
          await healthService.deleteHealthRecord(record.id);
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully')),
          );
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(HealthRecordModel record) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Health Record'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
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
    ) ?? false;
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

  IconData _getPetSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets;
      case PetSpecies.bird:
        return Icons.flight;
      case PetSpecies.rabbit:
        return Icons.pets;
      case PetSpecies.hamster:
        return Icons.pets;
      case PetSpecies.fish:
        return Icons.water;
      case PetSpecies.reptile:
        return Icons.pets;
      case PetSpecies.other:
        return Icons.pets;
    }
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays;
    
    if (age < 30) {
      return '$age days old';
    } else if (age < 365) {
      final months = (age / 30).floor();
      return '$months months old';
    } else {
      final years = (age / 365).floor();
      final remainingMonths = ((age % 365) / 30).floor();
      return remainingMonths > 0 ? '$years years $remainingMonths months old' : '$years years old';
    }
  }
}
