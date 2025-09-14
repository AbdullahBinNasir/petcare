import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pet_service.dart';
import '../../services/store_service.dart';
import '../../services/blog_service.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../models/pet_model.dart';
import '../../models/store_item_model.dart';
import '../../models/blog_post_model.dart';
import '../../models/appointment_model.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Search results
  List<PetModel> _petResults = [];
  List<StoreItemModel> _storeResults = [];
  List<BlogPostModel> _blogResults = [];
  List<AppointmentModel> _appointmentResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pets', icon: Icon(Icons.pets)),
            Tab(text: 'Store', icon: Icon(Icons.store)),
            Tab(text: 'Blog', icon: Icon(Icons.article)),
            Tab(text: 'Appointments', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPetsTab(),
                _buildStoreTab(),
                _buildBlogTab(),
                _buildAppointmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search pets, products, articles, appointments...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _performSearch,
        onSubmitted: (value) => _performSearch(value),
      ),
    );
  }

  Widget _buildPetsTab() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pets,
        title: 'Search Pets',
        subtitle: 'Find pets by name, breed, or medical requirements',
      );
    }

    if (_petResults.isEmpty) {
      return _buildNoResultsState('No pets found matching your search');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _petResults.length,
      itemBuilder: (context, index) {
        final pet = _petResults[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildStoreTab() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store,
        title: 'Search Store',
        subtitle: 'Find products by name, brand, or category',
      );
    }

    if (_storeResults.isEmpty) {
      return _buildNoResultsState('No products found matching your search');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _storeResults.length,
      itemBuilder: (context, index) {
        final item = _storeResults[index];
        return _buildStoreItemCard(item);
      },
    );
  }

  Widget _buildBlogTab() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.article,
        title: 'Search Blog',
        subtitle: 'Find articles by keywords or topics',
      );
    }

    if (_blogResults.isEmpty) {
      return _buildNoResultsState('No articles found matching your search');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blogResults.length,
      itemBuilder: (context, index) {
        final post = _blogResults[index];
        return _buildBlogCard(post);
      },
    );
  }

  Widget _buildAppointmentsTab() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'Search Appointments',
        subtitle: 'Find appointments by date, type, or status',
      );
    }

    if (_appointmentResults.isEmpty) {
      return _buildNoResultsState('No appointments found matching your search');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointmentResults.length,
      itemBuilder: (context, index) {
        final appointment = _appointmentResults[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.pets,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          pet.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pet.breed.isNotEmpty ? pet.breed : pet.species.toString().split('.').last} • ${pet.ageString}'),
            Text('Health: ${pet.healthStatus.toString().split('.').last}'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Navigate to pet details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing ${pet.name} details')),
          );
        },
      ),
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: item.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        item.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.category.toString().split('.').last,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BlogPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category.toString().split('.').last,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.excerpt,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  post.authorName,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(post.publishedAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
          child: Icon(
            _getAppointmentTypeIcon(appointment.type),
            color: _getAppointmentStatusColor(appointment.status),
          ),
        ),
        title: Text(
          appointment.type.toString().split('.').last,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}'),
            Text('Time: ${appointment.timeSlot}'),
            Text('Status: ${appointment.status.toString().split('.').last}'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Navigate to appointment details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viewing appointment details')),
          );
        },
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    if (query.isEmpty) {
      setState(() {
        _petResults.clear();
        _storeResults.clear();
        _blogResults.clear();
        _appointmentResults.clear();
        _isSearching = false;
      });
      return;
    }

    _searchPets(query);
    _searchStore(query);
    _searchBlog(query);
    _searchAppointments(query);
  }

  Future<void> _searchPets(String query) async {
    try {
      final petService = Provider.of<PetService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId != null) {
        final pets = await petService.getPetsByOwnerId(userId);
        final filteredPets = pets.where((pet) {
          return pet.name.toLowerCase().contains(query.toLowerCase()) ||
                 pet.breed.toLowerCase().contains(query.toLowerCase()) ||
                 pet.species.toString().toLowerCase().contains(query.toLowerCase()) ||
                 pet.healthStatus.toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        setState(() {
          _petResults = filteredPets;
        });
      }
    } catch (e) {
      debugPrint('Error searching pets: $e');
    }
  }

  Future<void> _searchStore(String query) async {
    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      storeService.searchItems(query);
      
      setState(() {
        _storeResults = storeService.storeItems;
      });
    } catch (e) {
      debugPrint('Error searching store: $e');
    }
  }

  Future<void> _searchBlog(String query) async {
    try {
      final blogService = Provider.of<BlogService>(context, listen: false);
      blogService.searchPosts(query);
      
      setState(() {
        _blogResults = blogService.blogPosts;
      });
    } catch (e) {
      debugPrint('Error searching blog: $e');
    }
  }

  Future<void> _searchAppointments(String query) async {
    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId != null) {
        final appointments = await appointmentService.getAppointmentsByPetOwner(userId);
        final filteredAppointments = appointments.where((appointment) {
          return appointment.type.toString().toLowerCase().contains(query.toLowerCase()) ||
                 appointment.status.toString().toLowerCase().contains(query.toLowerCase()) ||
                 appointment.timeSlot.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        setState(() {
          _appointmentResults = filteredAppointments;
        });
      }
    } catch (e) {
      debugPrint('Error searching appointments: $e');
    }
    
    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _petResults.clear();
      _storeResults.clear();
      _blogResults.clear();
      _appointmentResults.clear();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
