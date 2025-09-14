import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/contact_volunteer_form_service.dart';
import '../../models/contact_volunteer_form_model.dart';
import 'form_details_screen.dart';

class ContactVolunteerFormManagementScreen extends StatefulWidget {
  const ContactVolunteerFormManagementScreen({super.key});

  @override
  State<ContactVolunteerFormManagementScreen> createState() => _ContactVolunteerFormManagementScreenState();
}

class _ContactVolunteerFormManagementScreenState extends State<ContactVolunteerFormManagementScreen> {
  late String _shelterOwnerId;
  List<ContactVolunteerFormModel> _forms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  FormType? _selectedType;
  FormStatus? _selectedStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _shelterOwnerId = authService.currentUserModel?.id ?? '';
      
      print('🔐 Current user ID: $_shelterOwnerId');
      print('🔐 Current user model: ${authService.currentUserModel}');
      
      if (_shelterOwnerId.isEmpty) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }
      
      await _loadForms();
    } catch (e) {
      print('❌ Error in initializeData: $e');
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadForms() async {
    print('📱 Loading forms...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final formService = Provider.of<ContactVolunteerFormService>(context, listen: false);
      print('🔧 FormService instance: $formService');
      
      final forms = await formService.getFormsByShelterOwnerId(_shelterOwnerId);
      print('📊 Received ${forms.length} forms');
      
      if (mounted) {
        setState(() {
          _forms = forms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading forms: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading forms: $e';
        });
        _showErrorSnackBar('Error loading forms: $e');
      }
    }
  }

  Future<void> _searchForms() async {
    print('🔍 Searching forms with query: "$_searchQuery"');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final formService = Provider.of<ContactVolunteerFormService>(context, listen: false);
      final forms = await formService.searchForms(
        query: _searchQuery,
        shelterOwnerId: _shelterOwnerId,
        formType: _selectedType,
        status: _selectedStatus,
      );
      
      print('📊 Search returned ${forms.length} forms');
      
      if (mounted) {
        setState(() {
          _forms = forms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error searching forms: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error searching forms: $e';
        });
        _showErrorSnackBar('Error searching forms: $e');
      }
    }
  }

  Future<void> _updateFormStatus(String formId, FormStatus status, {String? response}) async {
    try {
      final formService = Provider.of<ContactVolunteerFormService>(context, listen: false);
      final success = await formService.updateFormStatus(
        formId, 
        status, 
        response: response,
      );
      if (success) {
        await _loadForms();
        _showSuccessSnackBar('Form status updated successfully');
      } else {
        _showErrorSnackBar('Failed to update form status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating form status: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forms Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForms,
          ),
          // Debug info button
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showDebugInfo,
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
                    hintText: 'Search forms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _loadForms();
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
                      _loadForms();
                    } else {
                      _searchForms();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<FormType?>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<FormType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...FormType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                          _searchForms();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<FormStatus?>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<FormStatus?>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...FormStatus.values.map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toString().split('.').last),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _searchForms();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Forms List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadForms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_forms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_mail, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No forms found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Forms will appear here when users submit them',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _forms.length,
      itemBuilder: (context, index) {
        final form = _forms[index];
        return _buildFormCard(form);
      },
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Shelter Owner ID: $_shelterOwnerId'),
              Text('Forms Count: ${_forms.length}'),
              Text('Is Loading: $_isLoading'),
              Text('Search Query: "$_searchQuery"'),
              Text('Selected Type: $_selectedType'),
              Text('Selected Status: $_selectedStatus'),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              const Text('Forms:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._forms.map((form) => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text('• ${form.subject} (${form.formType})'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ContactVolunteerFormModel form) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Form Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(form.formType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(form.formType),
                    color: _getTypeColor(form.formType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Form Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${form.formTypeDisplayName} • From ${form.submitterName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        form.timeSinceSubmission,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(form.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    form.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(form.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Form Message
            Text(
              form.message,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFormDetails(form),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (form.isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRespondDialog(form),
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Respond'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateFormStatus(form.id, FormStatus.closed),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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

  Color _getTypeColor(FormType type) {
    switch (type) {
      case FormType.contact:
        return Colors.blue;
      case FormType.volunteer:
        return Colors.green;
      case FormType.donation:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(FormType type) {
    switch (type) {
      case FormType.contact:
        return Icons.contact_mail;
      case FormType.volunteer:
        return Icons.volunteer_activism;
      case FormType.donation:
        return Icons.attach_money;
    }
  }

  Color _getStatusColor(FormStatus status) {
    switch (status) {
      case FormStatus.pending:
        return Colors.orange;
      case FormStatus.responded:
        return Colors.green;
      case FormStatus.closed:
        return Colors.grey;
    }
  }

  void _viewFormDetails(ContactVolunteerFormModel form) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormDetailsScreen(form: form),
      ),
    );
    if (result == true) {
      _loadForms();
    }
  }

  void _showRespondDialog(ContactVolunteerFormModel form) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Respond to Form'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Respond to ${form.submitterName}\'s ${form.formTypeDisplayName.toLowerCase()} form?'),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Your Response',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
                _updateFormStatus(
                  form.id, 
                  FormStatus.responded,
                  response: responseController.text.trim(),
                );
              },
              child: const Text('Send Response', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}