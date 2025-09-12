import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../services/auth_service.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import 'add_health_record_screen.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _vaccinationRecords = [];
  List<HealthRecordModel> _dewormingRecords = [];
  List<HealthRecordModel> _allergyRecords = [];
  List<HealthRecordModel> _upcomingReminders = [];
  Map<String, PetModel> _pets = {};
  PetModel? _selectedPet;
  bool _isLoading = true;
  String _searchQuery = '';
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Starting data load...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);

      debugPrint('HealthTrackingScreen: Starting data load...');
      
      if (authService.currentUserModel == null) {
        setState(() {
          _debugInfo = 'No authenticated user found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _debugInfo = 'Loading pets for user: ${authService.currentUserModel!.id}';
      });

      final pets = await petService.getPetsByOwnerId(authService.currentUserModel!.id);
      debugPrint('HealthTrackingScreen: Found ${pets.length} pets');
      
      setState(() {
        _debugInfo = 'Found ${pets.length} pets';
      });

      if (pets.isEmpty) {
        setState(() {
          _pets = {};
          _selectedPet = null;
          _debugInfo = 'No pets found for this user';
          _isLoading = false;
        });
        return;
      }

      // Convert to map and select first pet
      final petsMap = <String, PetModel>{};
      for (final pet in pets) {
        petsMap[pet.id] = pet;
      }

      setState(() {
        _pets = petsMap;
        _selectedPet = pets.first;
        _debugInfo = 'Selected pet: ${pets.first.name} (${pets.first.id})';
      });

      // Load records for the selected pet
      await _loadRecordsForPet(pets.first.id);

    } catch (e) {
      debugPrint('HealthTrackingScreen: Error in _loadData: $e');
      setState(() {
        _debugInfo = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecordsForPet(String petId) async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading records for pet: $petId';
    });

    try {
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      
      debugPrint('HealthTrackingScreen: Fetching records for pet: $petId');
      final allRecords = await healthService.getHealthRecordsByPetId(petId);
      debugPrint('HealthTrackingScreen: Retrieved ${allRecords.length} records');

      // Log each record
      for (int i = 0; i < allRecords.length; i++) {
        final record = allRecords[i];
        debugPrint('Record $i: ${record.title} - Type: ${record.type} - Pet: ${record.petId}');
      }

      // Filter records
      final vaccinationRecords = allRecords.where((r) => r.type == HealthRecordType.vaccination).toList();
      final medicationRecords = allRecords.where((r) => r.type == HealthRecordType.medication).toList();
      final allergyRecords = allRecords.where((r) => r.type == HealthRecordType.allergy).toList();
      final checkupRecords = allRecords.where((r) => r.type == HealthRecordType.checkup).toList();

      // Calculate upcoming reminders
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      final upcomingReminders = allRecords.where((record) => 
          record.nextDueDate != null && 
          record.nextDueDate!.isAfter(now) &&
          record.nextDueDate!.isBefore(thirtyDaysLater)).toList();

      setState(() {
        _allRecords = allRecords;
        _vaccinationRecords = vaccinationRecords;
        _dewormingRecords = medicationRecords; // Include all medications for now
        _allergyRecords = allergyRecords;
        _upcomingReminders = upcomingReminders;
        _isLoading = false;
        _debugInfo = 'Loaded ${allRecords.length} records (${vaccinationRecords.length} vaccinations, ${medicationRecords.length} medications, ${allergyRecords.length} allergies, ${checkupRecords.length} checkups)';
      });

      debugPrint('HealthTrackingScreen: State updated with ${_allRecords.length} records');

    } catch (e) {
      debugPrint('HealthTrackingScreen: Error loading records: $e');
      setState(() {
        _debugInfo = 'Error loading records: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load health records: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadRecordsForPet(petId),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview (${_allRecords.length})', icon: const Icon(Icons.dashboard)),
            Tab(text: 'Vaccinations (${_vaccinationRecords.length})', icon: const Icon(Icons.vaccines)),
            Tab(text: 'Medications (${_dewormingRecords.length})', icon: const Icon(Icons.medication)),
            Tab(text: 'Allergies (${_allergyRecords.length})', icon: const Icon(Icons.warning)),
            Tab(text: 'Reminders (${_upcomingReminders.length})', icon: const Icon(Icons.notifications)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading...'),
                  const SizedBox(height: 8),
                  Text(
                    _debugInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Debug Info Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEBUG INFO',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Status: $_debugInfo'),
                      Text('Pets Available: ${_pets.length}'),
                      if (_selectedPet != null)
                        Text('Selected Pet: ${_selectedPet!.name} (ID: ${_selectedPet!.id})'),
                      Text('Total Records: ${_allRecords.length}'),
                      Text('Vaccinations: ${_vaccinationRecords.length}'),
                      Text('Medications: ${_dewormingRecords.length}'),
                      Text('Allergies: ${_allergyRecords.length}'),
                      Text('Reminders: ${_upcomingReminders.length}'),
                    ],
                  ),
                ),
                
                // Pet Selector
                if (_pets.isNotEmpty) _buildPetSelector(),
                
                // Content
                Expanded(
                  child: _pets.isEmpty
                      ? _buildNoPetsView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildRecordsList(_vaccinationRecords, 'No vaccination records'),
                            _buildRecordsList(_dewormingRecords, 'No medication records'),
                            _buildRecordsList(_allergyRecords, 'No allergy records'),
                            _buildRecordsList(_upcomingReminders, 'No upcoming reminders'),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedPet != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddHealthRecordScreen(petId: _selectedPet!.id),
                  ),
                );
                if (result == true && _selectedPet != null) {
                  await _loadRecordsForPet(_selectedPet!.id);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
            )
          : null,
    );
  }

  Widget _buildNoPetsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Pets Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please add a pet first to start tracking health records',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<PetModel>(
        value: _selectedPet,
        decoration: const InputDecoration(
          labelText: 'Select Pet',
          prefixIcon: Icon(Icons.pets),
          border: OutlineInputBorder(),
        ),
        items: _pets.values.map((pet) {
          return DropdownMenuItem(
            value: pet,
            child: Text('${pet.name} - ${pet.breed}'),
          );
        }).toList(),
        onChanged: (pet) async {
          if (pet != null) {
            setState(() {
              _selectedPet = pet;
              _allRecords = [];
              _vaccinationRecords = [];
              _dewormingRecords = [];
              _allergyRecords = [];
              _upcomingReminders = [];
            });
            await _loadRecordsForPet(pet.id);
          }
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Records', _allRecords.length.toString(), Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Vaccinations', _vaccinationRecords.length.toString(), Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'All Records',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (_allRecords.isEmpty) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.medical_services, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Health Records Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Add your first health record to get started'),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            ..._allRecords.map((record) => _buildRecordCard(record)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(List<HealthRecordModel> records, String emptyMessage) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('No records found in this category'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(records[index]);
      },
    );
  }

  Widget _buildRecordCard(HealthRecordModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRecordTypeIcon(record.type),
                  color: _getRecordTypeColor(record.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRecordTypeColor(record.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRecordTypeName(record.type),
                    style: TextStyle(
                      color: _getRecordTypeColor(record.type),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (record.description.isNotEmpty) ...[
              Text(
                record.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            
            Text('Date: ${_formatDate(record.recordDate)}'),
            
            if (record.nextDueDate != null)
              Text('Next Due: ${_formatDate(record.nextDueDate!)}'),
            
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${record.notes!}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRecordTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Colors.green;
      case HealthRecordType.medication:
        return Colors.orange;
      case HealthRecordType.allergy:
        return Colors.red;
      case HealthRecordType.checkup:
        return Colors.blue;
      case HealthRecordType.surgery:
        return Colors.purple;
      case HealthRecordType.injury:
        return Colors.red;
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
      case HealthRecordType.allergy:
        return Icons.warning;
      case HealthRecordType.checkup:
        return Icons.medical_services;
      case HealthRecordType.surgery:
        return Icons.healing;
      case HealthRecordType.injury:
        return Icons.emergency;
      case HealthRecordType.other:
        return Icons.medical_information;
    }
  }

  String _getRecordTypeName(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.allergy:
        return 'Allergy';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.injury:
        return 'Injury';
      case HealthRecordType.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
