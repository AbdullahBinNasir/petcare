import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/pet_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class VetAppointmentFiltersScreen extends StatefulWidget {
  const VetAppointmentFiltersScreen({super.key});

  @override
  State<VetAppointmentFiltersScreen> createState() => _VetAppointmentFiltersScreenState();
}

class _VetAppointmentFiltersScreenState extends State<VetAppointmentFiltersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  Map<String, PetModel> _pets = {};
  Map<String, UserModel> _petOwners = {};
  
  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  AppointmentStatus? _selectedStatus;
  AppointmentType? _selectedType;
  String? _selectedPetId;
  String? _selectedOwnerId;
  String _searchQuery = '';
  
  bool _isLoading = true;
  String _sortBy = 'date'; // date, status, type, pet
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      if (authService.currentUser != null) {
        // Load appointments
        final appointments = await appointmentService.getAppointmentsByVeterinarian(authService.currentUser!.uid);
        
        // Load pet and owner information
        final petIds = appointments.map((a) => a.petId).toSet();
        final ownerIds = appointments.map((a) => a.petOwnerId).toSet();
        
        final pets = <String, PetModel>{};
        final owners = <String, UserModel>{};
        
        for (final petId in petIds) {
          final pet = await petService.getPetById(petId);
          if (pet != null) {
            pets[petId] = pet;
          }
        }
        
        for (final ownerId in ownerIds) {
          final owner = await userService.getUserById(ownerId);
          if (owner != null) {
            owners[ownerId] = owner;
          }
        }

        setState(() {
          _allAppointments = appointments;
          _filteredAppointments = appointments;
          _pets = pets;
          _petOwners = owners;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointment data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAppointments = _allAppointments.where((appointment) {
        // Date filter
        if (_startDate != null && appointment.appointmentDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && appointment.appointmentDate.isAfter(_endDate!)) {
          return false;
        }
        
        // Status filter
        if (_selectedStatus != null && appointment.status != _selectedStatus) {
          return false;
        }
        
        // Type filter
        if (_selectedType != null && appointment.type != _selectedType) {
          return false;
        }
        
        // Pet filter
        if (_selectedPetId != null && appointment.petId != _selectedPetId) {
          return false;
        }
        
        // Owner filter
        if (_selectedOwnerId != null && appointment.petOwnerId != _selectedOwnerId) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final pet = _pets[appointment.petId];
          final owner = _petOwners[appointment.petOwnerId];
          final searchLower = _searchQuery.toLowerCase();
          
          final matchesSearch = appointment.reason.toLowerCase().contains(searchLower) ||
              (appointment.notes?.toLowerCase().contains(searchLower) ?? false) ||
              (pet?.name.toLowerCase().contains(searchLower) ?? false) ||
              (owner?.fullName.toLowerCase().contains(searchLower) ?? false);
          
          if (!matchesSearch) return false;
        }
        
        return true;
      }).toList();
      
      _sortAppointments();
    });
  }

  void _sortAppointments() {
    _filteredAppointments.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'date':
          comparison = a.appointmentDate.compareTo(b.appointmentDate);
          break;
        case 'status':
          comparison = a.status.toString().compareTo(b.status.toString());
          break;
        case 'type':
          comparison = a.type.toString().compareTo(b.type.toString());
          break;
        case 'pet':
          final petA = _pets[a.petId]?.name ?? '';
          final petB = _pets[b.petId]?.name ?? '';
          comparison = petA.compareTo(petB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedStatus = null;
      _selectedType = null;
      _selectedPetId = null;
      _selectedOwnerId = null;
      _searchQuery = '';
      _searchController.clear();
      _filteredAppointments = _allAppointments;
      _sortAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltersSection(),
                const Divider(),
                _buildSortSection(),
                const Divider(),
                _buildResultsSection(),
              ],
            ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Appointments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by reason, pet name, or owner...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          
          // Date range filters
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_startDate != null 
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select start date'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_endDate != null 
                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                        : 'Select end date'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status and Type filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AppointmentStatus?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...AppointmentStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<AppointmentType?>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...AppointmentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pet and Owner filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedPetId,
                  decoration: const InputDecoration(
                    labelText: 'Pet',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Pets'),
                    ),
                    ..._pets.values.map((pet) {
                      return DropdownMenuItem(
                        value: pet.id,
                        child: Text(
                          pet.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedPetId = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedOwnerId,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Owners'),
                    ),
                    ..._petOwners.values.map((owner) {
                      return DropdownMenuItem(
                        value: owner.id,
                        child: Text(
                          owner.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedOwnerId = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'date', child: Text('Date')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'type', child: Text('Type')),
                DropdownMenuItem(value: 'pet', child: Text('Pet')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _sortAppointments();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
              _sortAppointments();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results (${_filteredAppointments.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_filteredAppointments.length != _allAppointments.length)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAppointments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No appointments found matching your filters'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _filteredAppointments[index];
                      final pet = _pets[appointment.petId];
                      final owner = _petOwners[appointment.petOwnerId];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(appointment.status).withOpacity(0.1),
                            child: Icon(
                              _getTypeIcon(appointment.type),
                              color: _getStatusColor(appointment.status),
                            ),
                          ),
                          title: Text(appointment.reason),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pet != null) Text('Pet: ${pet.name}'),
                              if (owner != null) Text('Owner: ${owner.fullName}'),
                              Text('${DateFormat('MMM dd, yyyy').format(appointment.appointmentDate)} at ${appointment.timeSlot}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appointment.status.toString().split('.').last,
                                  style: TextStyle(
                                    color: _getStatusColor(appointment.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment.type.toString().split('.').last,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _startDate = date);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _endDate = date);
      _applyFilters();
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
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

  IconData _getTypeIcon(AppointmentType type) {
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
