import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/adoption_request_service.dart';
import '../../models/adoption_request_model.dart';
import 'adoption_request_details_screen.dart';

class AdoptionRequestManagementScreen extends StatefulWidget {
  const AdoptionRequestManagementScreen({super.key});

  @override
  State<AdoptionRequestManagementScreen> createState() => _AdoptionRequestManagementScreenState();
}

class _AdoptionRequestManagementScreenState extends State<AdoptionRequestManagementScreen> {
  late String _shelterOwnerId;
  List<AdoptionRequestModel> _adoptionRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  AdoptionRequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _shelterOwnerId = authService.currentUserModel?.id ?? '';
    _loadAdoptionRequests();
  }

  Future<void> _loadAdoptionRequests() async {
    setState(() => _isLoading = true);
    try {
      final adoptionRequestService = Provider.of<AdoptionRequestService>(context, listen: false);
      final adoptionRequests = await adoptionRequestService.getAdoptionRequestsByShelterOwnerId(_shelterOwnerId);
      setState(() {
        _adoptionRequests = adoptionRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading adoption requests: $e');
    }
  }

  Future<void> _searchAdoptionRequests() async {
    setState(() => _isLoading = true);
    try {
      final adoptionRequestService = Provider.of<AdoptionRequestService>(context, listen: false);
      final adoptionRequests = await adoptionRequestService.searchAdoptionRequests(
        query: _searchQuery,
        shelterOwnerId: _shelterOwnerId,
        status: _selectedStatus,
      );
      setState(() {
        _adoptionRequests = adoptionRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error searching adoption requests: $e');
    }
  }

  Future<void> _updateRequestStatus(String requestId, AdoptionRequestStatus status, {String? response}) async {
    try {
      final adoptionRequestService = Provider.of<AdoptionRequestService>(context, listen: false);
      final success = await adoptionRequestService.updateAdoptionRequestStatus(
        requestId, 
        status, 
        response: response,
      );
      if (success) {
        _loadAdoptionRequests();
        _showSuccessSnackBar('Request status updated successfully');
      } else {
        _showErrorSnackBar('Failed to update request status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating request status: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Requests Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdoptionRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search adoption requests...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _loadAdoptionRequests();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    if (value.isEmpty) {
                      _loadAdoptionRequests();
                    } else {
                      _searchAdoptionRequests();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AdoptionRequestStatus?>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<AdoptionRequestStatus?>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...AdoptionRequestStatus.values.map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toString().split('.').last),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _searchAdoptionRequests();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Adoption Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _adoptionRequests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No adoption requests found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Adoption requests will appear here when pet owners apply',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _adoptionRequests.length,
                        itemBuilder: (context, index) {
                          final request = _adoptionRequests[index];
                          return _buildAdoptionRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdoptionRequestCard(AdoptionRequestModel request) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.petType} • Requested by ${request.petOwnerName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDate(request.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    request.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Request Details
            Text(
              'Reason: ${request.reasonForAdoption}',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Experience: ${request.experienceWithPets}',
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRequestDetails(request),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (request.isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AdoptionRequestStatus status) {
    switch (status) {
      case AdoptionRequestStatus.pending:
        return Colors.orange;
      case AdoptionRequestStatus.approved:
        return Colors.green;
      case AdoptionRequestStatus.rejected:
        return Colors.red;
      case AdoptionRequestStatus.cancelled:
        return Colors.grey;
      case AdoptionRequestStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewRequestDetails(AdoptionRequestModel request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdoptionRequestDetailsScreen(adoptionRequest: request),
      ),
    );
    if (result == true) {
      _loadAdoptionRequests();
    }
  }

  void _showApproveDialog(AdoptionRequestModel request) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Adoption Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Approve ${request.petOwnerName}\'s request for ${request.petName}?'),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Response Message (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateRequestStatus(
                  request.id, 
                  AdoptionRequestStatus.approved,
                  response: responseController.text.trim().isEmpty 
                      ? null 
                      : responseController.text.trim(),
                );
              },
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(AdoptionRequestModel request) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Adoption Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject ${request.petOwnerName}\'s request for ${request.petName}?'),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateRequestStatus(
                  request.id, 
                  AdoptionRequestStatus.rejected,
                  response: responseController.text.trim().isEmpty 
                      ? 'Request rejected' 
                      : responseController.text.trim(),
                );
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
