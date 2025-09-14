import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pet_model.dart';
import '../../models/health_record_model.dart';
import '../../models/appointment_model.dart';
import '../../services/pet_service.dart';
import '../../services/health_record_service.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../shared/add_health_record_screen.dart';

class VetPetSearchScreen extends StatefulWidget {
  const VetPetSearchScreen({super.key});

  @override
  State<VetPetSearchScreen> createState() => _VetPetSearchScreenState();
}

class _VetPetSearchScreenState extends State<VetPetSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<PetModel> _searchResults = [];
  List<PetModel> _recentPets = [];
  Map<String, List<HealthRecordModel>> _petHealthRecords = {};
  Map<String, List<AppointmentModel>> _petAppointments = {};
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecentPets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentPets() async {
    setState(() => _isLoading = true);

    try {
      final petService = Provider.of<PetService>(context, listen: false);
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Get all pets (veterinarians can search all pets)
      final allPets = await petService.searchPets(query: '');
      
      // Get recent pets (pets with recent health records or appointments)
      final recentPetIds = <String>{};
      
      // Get pets with recent health records
      final healthRecords = await healthService.getAllHealthRecords();
      final recentHealthRecords = healthRecords.where((record) {
        return record.recordDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).toList();
      
      for (final record in recentHealthRecords) {
        recentPetIds.add(record.petId);
      }

      // Get pets with recent appointments
      final allAppointments = await appointmentService.searchAppointments();
      final recentAppointments = allAppointments.where((appointment) {
        return appointment.appointmentDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).toList();
      
      for (final appointment in recentAppointments) {
        recentPetIds.add(appointment.petId);
      }

      final recentPets = allPets.where((pet) => recentPetIds.contains(pet.id)).toList();
      recentPets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      setState(() {
        _recentPets = recentPets.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recent pets: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPets(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final petService = Provider.of<PetService>(context, listen: false);
      final results = await petService.searchPets(query: query);
      
      // Apply filter
      List<PetModel> filteredResults = results;
      if (_selectedFilter != 'all') {
        filteredResults = results.where((pet) {
          switch (_selectedFilter) {
            case 'dogs':
              return pet.species == PetSpecies.dog;
            case 'cats':
              return pet.species == PetSpecies.cat;
            case 'sick':
              return pet.healthStatus == HealthStatus.sick;
            case 'critical':
              return pet.healthStatus == HealthStatus.critical;
            default:
              return true;
          }
        }).toList();
      }

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error searching pets: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPetDetails(String petId) async {
    try {
      final healthService = Provider.of<HealthRecordService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      final healthRecords = await healthService.getHealthRecordsByPetId(petId);
      final appointments = await appointmentService.getAppointmentsByPet(petId);

      setState(() {
        _petHealthRecords[petId] = healthRecords;
        _petAppointments[petId] = appointments;
      });
    } catch (e) {
      debugPrint('Error loading pet details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Search'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
              if (_searchController.text.isNotEmpty) {
                _searchPets(_searchController.text);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Pets')),
              const PopupMenuItem(value: 'dogs', child: Text('Dogs Only')),
              const PopupMenuItem(value: 'cats', child: Text('Cats Only')),
              const PopupMenuItem(value: 'sick', child: Text('Sick Pets')),
              const PopupMenuItem(value: 'critical', child: Text('Critical Pets')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Recent', icon: Icon(Icons.history)),
            Tab(text: 'All Pets', icon: Icon(Icons.pets)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildRecentTab(),
          _buildAllPetsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by pet name, breed, or species...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchPets,
          ),
        ),
        if (_selectedFilter != 'all')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filter: ${_selectedFilter.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPetList(_searchResults, 'No pets found matching your search'),
        ),
      ],
    );
  }

  Widget _buildRecentTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildPetList(_recentPets, 'No recent pets found');
  }

  Widget _buildAllPetsTab() {
    return FutureBuilder<List<PetModel>>(
      future: Provider.of<PetService>(context, listen: false).searchPets(query: ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData) {
          return const Center(child: Text('Error loading pets'));
        }
        
        return _buildPetList(snapshot.data!, 'No pets found');
      },
    );
  }

  Widget _buildPetList(List<PetModel> pets, String emptyMessage) {
    if (pets.isEmpty) {
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
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPetDetails(pet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: pet.photoUrls.isNotEmpty
                    ? NetworkImage(pet.photoUrls.first)
                    : null,
                child: pet.photoUrls.isEmpty
                    ? Icon(
                        _getPetSpeciesIcon(pet.species),
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.species.toString().split('.').last} • ${pet.breed}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (pet.dateOfBirth != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Age: ${_calculateAge(pet.dateOfBirth!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getHealthStatusColor(pet.healthStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pet.healthStatus.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: _getHealthStatusColor(pet.healthStatus),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pet.weight != null)
                          Text(
                            '${pet.weight!.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handlePetAction(value, pet),
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
                    value: 'health',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services),
                        SizedBox(width: 8),
                        Text('Health Records'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'appointments',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 8),
                        Text('Appointments'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_record',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Add Health Record'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPetDetails(PetModel pet) {
    _loadPetDetails(pet.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: pet.photoUrls.isNotEmpty
                  ? NetworkImage(pet.photoUrls.first)
                  : null,
              child: pet.photoUrls.isEmpty
                  ? Icon(_getPetSpeciesIcon(pet.species))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(pet.name)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Species', pet.species.toString().split('.').last),
                _buildDetailRow('Breed', pet.breed),
                _buildDetailRow('Gender', pet.gender.toString().split('.').last),
                if (pet.dateOfBirth != null)
                  _buildDetailRow('Age', _calculateAge(pet.dateOfBirth!)),
                if (pet.weight != null)
                  _buildDetailRow('Weight', '${pet.weight!.toStringAsFixed(1)} kg'),
                if (pet.color != null)
                  _buildDetailRow('Color', pet.color!),
                if (pet.microchipId != null)
                  _buildDetailRow('Microchip ID', pet.microchipId!),
                _buildDetailRow('Health Status', pet.healthStatus.toString().split('.').last),
                if (pet.medicalNotes != null) ...[
                  const SizedBox(height: 8),
                  const Text('Medical Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(pet.medicalNotes!),
                ],
                const SizedBox(height: 16),
                const Text('Recent Health Records:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildHealthRecordsPreview(pet.id),
                const SizedBox(height: 16),
                const Text('Recent Appointments:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAppointmentsPreview(pet.id),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddRecord(pet.id);
            },
            child: const Text('Add Health Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildHealthRecordsPreview(String petId) {
    final records = _petHealthRecords[petId] ?? [];
    if (records.isEmpty) {
      return const Text('No health records found');
    }
    
    return Column(
      children: records.take(3).map((record) {
        return ListTile(
          dense: true,
          leading: Icon(
            _getRecordTypeIcon(record.type),
            size: 16,
            color: _getRecordTypeColor(record.type),
          ),
          title: Text(record.title),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(record.recordDate)),
        );
      }).toList(),
    );
  }

  Widget _buildAppointmentsPreview(String petId) {
    final appointments = _petAppointments[petId] ?? [];
    if (appointments.isEmpty) {
      return const Text('No appointments found');
    }
    
    return Column(
      children: appointments.take(3).map((appointment) {
        return ListTile(
          dense: true,
          leading: Icon(
            _getAppointmentTypeIcon(appointment.type),
            size: 16,
            color: _getAppointmentStatusColor(appointment.status),
          ),
          title: Text(appointment.reason),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(appointment.appointmentDate)),
        );
      }).toList(),
    );
  }

  void _handlePetAction(String action, PetModel pet) {
    switch (action) {
      case 'view':
        _showPetDetails(pet);
        break;
      case 'health':
        // Navigate to health records screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health records screen coming soon')),
        );
        break;
      case 'appointments':
        // Navigate to appointments screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointments screen coming soon')),
        );
        break;
      case 'add_record':
        _navigateToAddRecord(pet.id);
        break;
    }
  }

  void _navigateToAddRecord(String petId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthRecordScreen(petId: petId),
      ),
    );
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

  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.sick:
        return Colors.orange;
      case HealthStatus.recovering:
        return Colors.blue;
      case HealthStatus.critical:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
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

  Color _getAppointmentStatusColor(AppointmentStatus status) {
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
}
