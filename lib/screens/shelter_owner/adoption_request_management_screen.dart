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
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFFFAFAF0))),
        backgroundColor: const Color(0xFFDC143C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFFFAFAF0))),
        backgroundColor: const Color(0xFF228B22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF0),
      appBar: AppBar(
        title: const Text(
          'Adoption Requests Management',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF7D4D20),
        foregroundColor: const Color(0xFFFAFAF0),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFAFAF0)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAdoptionRequests,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7D4D20).withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7D4D20).withOpacity(0.2),
                      ),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search adoption requests...',
                        hintStyle: TextStyle(color: const Color(0xFF7D4D20).withOpacity(0.6)),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF7D4D20).withOpacity(0.7),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7D4D20).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  color: const Color(0xFF7D4D20),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _loadAdoptionRequests();
                                  },
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(color: Color(0xFF7D4D20)),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        if (value.isEmpty) {
                          _loadAdoptionRequests();
                        } else {
                          _searchAdoptionRequests();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Row
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7D4D20).withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<AdoptionRequestStatus?>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                        labelStyle: TextStyle(color: Color(0xFF7D4D20)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      dropdownColor: const Color(0xFFFAFAF0),
                      style: const TextStyle(color: Color(0xFF7D4D20)),
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
            ),
          ),
          // Adoption Requests List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7D4D20),
                      strokeWidth: 3,
                    ),
                  )
                : _adoptionRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7D4D20).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.favorite_outline_rounded,
                                size: 64,
                                color: const Color(0xFF7D4D20).withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No adoption requests found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7D4D20),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adoption requests will appear here when pet owners apply',
                              style: TextStyle(
                                color: const Color(0xFF7D4D20).withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _adoptionRequests.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D4D20).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pet Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: Color(0xFF7D4D20),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                          color: Color(0xFF7D4D20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.petType} • Requested by ${request.petOwnerName}',
                        style: TextStyle(
                          color: const Color(0xFF7D4D20).withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submitted: ${_formatDate(request.createdAt)}',
                        style: TextStyle(
                          color: const Color(0xFF7D4D20).withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    request.statusDisplayName,
                    style: const TextStyle(
                      color: Color(0xFFFAFAF0),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Request Details Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAF0).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: const Color(0xFF7D4D20).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7D4D20),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.reasonForAdoption,
                    style: TextStyle(
                      color: const Color(0xFF7D4D20).withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 16,
                        color: const Color(0xFF7D4D20).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Experience:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7D4D20),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.experienceWithPets,
                    style: TextStyle(
                      color: const Color(0xFF7D4D20).withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF7D4D20)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _viewRequestDetails(request),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Color(0xFF7D4D20),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'View Details',
                                style: TextStyle(
                                  color: Color(0xFF7D4D20),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (request.isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF228B22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showApproveDialog(request),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Color(0xFFFAFAF0),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Approve',
                                  style: TextStyle(
                                    color: Color(0xFFFAFAF0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC143C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showRejectDialog(request),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFFFAFAF0),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Color(0xFFFAFAF0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
        return const Color(0xFFFF8C00); // Dark Orange
      case AdoptionRequestStatus.approved:
        return const Color(0xFF228B22); // Forest Green
      case AdoptionRequestStatus.rejected:
        return const Color(0xFFDC143C); // Crimson
      case AdoptionRequestStatus.cancelled:
        return const Color(0xFF696969); // Dim Gray
      case AdoptionRequestStatus.completed:
        return const Color(0xFF4169E1); // Royal Blue
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
          backgroundColor: const Color(0xFFFAFAF0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF228B22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF228B22),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Approve Request',
                style: TextStyle(
                  color: Color(0xFF7D4D20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approve ${request.petOwnerName}\'s request for ${request.petName}?',
                style: TextStyle(
                  color: const Color(0xFF7D4D20).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7D4D20).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'Response Message (Optional)',
                    labelStyle: TextStyle(color: Color(0xFF7D4D20)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: Color(0xFF7D4D20)),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7D4D20).withOpacity(0.7),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                foregroundColor: const Color(0xFFFAFAF0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Approve'),
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
          backgroundColor: const Color(0xFFFAFAF0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Color(0xFFDC143C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reject Request',
                style: TextStyle(
                  color: Color(0xFF7D4D20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject ${request.petOwnerName}\'s request for ${request.petName}?',
                style: TextStyle(
                  color: const Color(0xFF7D4D20).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7D4D20).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Rejection',
                    labelStyle: TextStyle(color: Color(0xFF7D4D20)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: Color(0xFF7D4D20)),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7D4D20).withOpacity(0.7),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: const Color(0xFFFAFAF0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}