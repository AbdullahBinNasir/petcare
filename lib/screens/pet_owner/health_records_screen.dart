import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../services/auth_service.dart';
import '../../services/health_record_service.dart';
import '../../services/pet_service.dart';
import 'add_health_record_screen.dart';

class HealthRecordsScreen extends StatefulWidget {
  final String? petId;
  
  const HealthRecordsScreen({super.key, this.petId});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecordModel> _allRecords = [];
  List<HealthRecordModel> _dueRecords = [];
  List<HealthRecordModel> _overdueRecords = [];
  Map<String, PetModel> _pets = {};
  PetModel? _selectedPet;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final petService = Provider.of<PetService>(context, listen: false);
    final healthService = Provider.of<HealthRecordService>(context, listen: false);

    debugPrint('HealthRecordsScreen: Starting data load...');
    debugPrint('HealthRecordsScreen: Current user model: ${authService.currentUserModel?.id}');
    debugPrint('HealthRecordsScreen: Current user: ${authService.currentUser?.uid}');

    if (authService.currentUserModel != null) {
      debugPrint('HealthRecordsScreen: Fetching pets for user: ${authService.currentUserModel!.id}');
      final pets = await petService.getPetsByOwnerId(authService.currentUserModel!.id);
      debugPrint('HealthRecordsScreen: Found ${pets.length} pets');
      
      final petsMap = <String, PetModel>{};
      for (final pet in pets) {
        petsMap[pet.id] = pet;
        debugPrint('HealthRecordsScreen: Pet - ID: ${pet.id}, Name: ${pet.name}');
      }

      // Set selected pet
      if (widget.petId != null && petsMap.containsKey(widget.petId)) {
        _selectedPet = petsMap[widget.petId];
        debugPrint('HealthRecordsScreen: Using widget pet ID: ${widget.petId}');
      } else if (pets.isNotEmpty) {
        _selectedPet = pets.first;
        debugPrint('HealthRecordsScreen: Using first pet: ${_selectedPet!.id}');
      }

      if (_selectedPet != null) {
        debugPrint('HealthRecordsScreen: Loading records for pet: ${_selectedPet!.id} (${_selectedPet!.name})');
        
        final allRecords = await healthService.getHealthRecordsByPetId(_selectedPet!.id);
        final dueRecords = await healthService.getDueHealthRecords(_selectedPet!.id);
        final overdueRecords = await healthService.getOverdueHealthRecords(_selectedPet!.id);

        debugPrint('HealthRecordsScreen: Loaded ${allRecords.length} all records, ${dueRecords.length} due records, ${overdueRecords.length} overdue records');

        setState(() {
          _pets = petsMap;
          _allRecords = allRecords;
          _dueRecords = dueRecords;
          _overdueRecords = overdueRecords;
          _isLoading = false;
        });
      } else {
        debugPrint('HealthRecordsScreen: No selected pet, cannot load health records');
        setState(() {
          _pets = petsMap;
          _isLoading = false;
        });
      }
    } else {
      debugPrint('HealthRecordsScreen: No current user model found');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecordsForPet(String petId) async {
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    final allRecords = await healthService.getHealthRecordsByPetId(petId);
    final dueRecords = await healthService.getDueHealthRecords(petId);
    final overdueRecords = await healthService.getOverdueHealthRecords(petId);

    setState(() {
      _allRecords = allRecords;
      _dueRecords = dueRecords;
      _overdueRecords = overdueRecords;
    });
  }

  Future<void> _testFetchAllRecords() async {
    debugPrint('Testing fetch of ALL health records...');
    final healthService = Provider.of<HealthRecordService>(context, listen: false);
    
    try {
      final allRecords = await healthService.getAllHealthRecords();
      debugPrint('Test fetch completed. Found ${allRecords.length} records');
      
      // Update the UI state with the fetched records
      setState(() {
        _allRecords = allRecords;
        _dueRecords = allRecords.where((record) => record.isDue).toList();
        _overdueRecords = allRecords.where((record) => record.isOverdue).toList();
      });
      
      // Always create a test record for debugging
      debugPrint('Creating test record for debugging...');
      final testRecord = HealthRecordModel(
        id: 'test_record_1',
        petId: _selectedPet?.id ?? 'test_pet',
        veterinarianId: 'test_vet',
        type: HealthRecordType.checkup,
        title: 'Test Health Record - Should Be Visible',
        description: 'This is a test health record for debugging. If you can see this, the UI is working!',
        recordDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _allRecords = [testRecord, ...allRecords];
        _dueRecords = [];
        _overdueRecords = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug: Found ${allRecords.length} total health records and updated UI'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('Test fetch failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug: Error - $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _testFetchAllRecords,
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Debug', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
        bottom: _selectedPet != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allRecords.length})'),
            Tab(text: 'Due (${_dueRecords.length})'),
            Tab(text: 'Overdue (${_overdueRecords.length})'),
          ],
        ) : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildNoPetsView()
              : Column(
                  children: [
                    _buildPetSelector(),
                    if (_selectedPet != null) _buildSearchBar(),
                    Expanded(
                      child: _selectedPet == null
                          ? _buildSelectPetView()
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildAllRecordsTab(),
                                _buildDueRecordsTab(),
                                _buildOverdueRecordsTab(),
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
                if (result == true) {
                  _loadRecordsForPet(_selectedPet!.id);
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
          Icon(
            Icons.pets,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pets Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a pet first to manage health records',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPetView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Pet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a pet to view their health records',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelector() {
    if (_pets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<PetModel>(
        initialValue: _selectedPet,
        decoration: const InputDecoration(
          labelText: 'Select Pet',
          prefixIcon: Icon(Icons.pets),
          border: OutlineInputBorder(),
        ),
        items: _pets.values.map((pet) {
          return DropdownMenuItem(
            value: pet,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.pets, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pet.name),
                      Text(
                        '${pet.breed} • ${pet.ageString}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (pet) {
          debugPrint('Pet selector changed: ${pet?.id} (${pet?.name})');
          setState(() => _selectedPet = pet);
          if (pet != null) {
            debugPrint('Loading records for selected pet: ${pet.id}');
            _loadRecordsForPet(pet.id);
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search health records...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildAllRecordsTab() {
    debugPrint('_buildAllRecordsTab: _allRecords.length = ${_allRecords.length}');
    debugPrint('_buildAllRecordsTab: _selectedPet = ${_selectedPet?.id}');
    
    // Force create a test record for debugging
    List<HealthRecordModel> recordsToShow = _allRecords;
    if (recordsToShow.isEmpty) {
      debugPrint('_buildAllRecordsTab: Creating test record for debugging');
      recordsToShow = [
        HealthRecordModel(
          id: 'debug_test_record',
          petId: _selectedPet?.id ?? 'debug_pet',
          veterinarianId: 'debug_vet',
          type: HealthRecordType.checkup,
          title: 'Debug Test Record - FORCE VISIBLE',
          description: 'This is a test health record for debugging purposes. This should definitely be visible on screen!',
          recordDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }
    
    final filteredRecords = _filterRecords(recordsToShow);
    debugPrint('_buildAllRecordsTab: filteredRecords.length = ${filteredRecords.length}');
    
    // Debug: Show test record if no records found
    if (filteredRecords.isEmpty) {
      debugPrint('_buildAllRecordsTab: Showing empty state');
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Debug Info: _allRecords.length = ${_allRecords.length}, _selectedPet = ${_selectedPet?.id}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          Expanded(
            child: _buildEmptyState(
              'No Health Records',
              'Start tracking your pet\'s health by adding their first record',
              Icons.medical_services,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecordsForPet(_selectedPet!.id),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Debug info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                'Debug: Showing ${filteredRecords.length} records',
                style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            // Health records
            ...filteredRecords.map((record) {
              debugPrint('Building health record card for: ${record.title}');
              return _buildHealthRecordCard(record);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDueRecordsTab() {
    final filteredRecords = _filterRecords(_dueRecords);
    
    if (filteredRecords.isEmpty) {
      return _buildEmptyState(
        'No Due Records',
        'All health records are up to date!',
        Icons.check_circle,
        color: Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecordsForPet(_selectedPet!.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRecords[index];
          return _buildHealthRecordCard(record, showDueIndicator: true);
        },
      ),
    );
  }

  Widget _buildOverdueRecordsTab() {
    final filteredRecords = _filterRecords(_overdueRecords);
    
    if (filteredRecords.isEmpty) {
      return _buildEmptyState(
        'No Overdue Records',
        'Great! No health records are overdue',
        Icons.check_circle,
        color: Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecordsForPet(_selectedPet!.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRecords[index];
          return _buildHealthRecordCard(record, showOverdueIndicator: true);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, {Color? color}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: color ?? Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordCard(HealthRecordModel record, {bool showDueIndicator = false, bool showOverdueIndicator = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRecordTypeColor(record.type).withOpacity(0.1),
                  child: Icon(
                    _getRecordTypeIcon(record.type),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getRecordTypeName(record.type),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDueIndicator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Due',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (showOverdueIndicator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(record.recordDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (record.nextDueDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Next: ${_formatDate(record.nextDueDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            if (record.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                record.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (record.medication != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medication, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.medication!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<HealthRecordModel> _filterRecords(List<HealthRecordModel> records) {
    if (_searchQuery.isEmpty) return records;
    
    final query = _searchQuery.toLowerCase();
    return records.where((record) {
      return record.title.toLowerCase().contains(query) ||
             record.description.toLowerCase().contains(query) ||
             (record.medication?.toLowerCase().contains(query) ?? false);
    }).toList();
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
