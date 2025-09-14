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

  // Custom colors
  static const Color primaryColor = Color(0xFF7D4D20);
  static const Color backgroundColor = Color(0xFFFAFAF0);
  static const Color cardColor = Colors.white;
  static const Color accentColor = Color(0xFF9A6B39);
  static const Color lightAccent = Color(0xFFE8DCC8);

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
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Forms Management',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadForms,
              tooltip: 'Refresh Forms',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              onPressed: _showDebugInfo,
              tooltip: 'Debug Info',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightAccent, width: 1.5),
                    color: backgroundColor.withOpacity(0.5),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search forms...',
                      hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  _loadForms();
                                },
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      if (value.isEmpty) {
                        _loadForms();
                      } else {
                        _searchForms();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lightAccent, width: 1.5),
                          color: backgroundColor.withOpacity(0.5),
                        ),
                        child: DropdownButtonFormField<FormType?>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                          dropdownColor: backgroundColor,
                          items: [
                            DropdownMenuItem<FormType?>(
                              value: null,
                              child: Text('All Types', style: TextStyle(color: primaryColor)),
                            ),
                            ...FormType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.toString().split('.').last,
                                style: TextStyle(color: primaryColor),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedType = value);
                            _searchForms();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lightAccent, width: 1.5),
                          color: backgroundColor.withOpacity(0.5),
                        ),
                        child: DropdownButtonFormField<FormStatus?>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                          dropdownColor: backgroundColor,
                          items: [
                            DropdownMenuItem<FormStatus?>(
                              value: null,
                              child: Text('All Statuses', style: TextStyle(color: primaryColor)),
                            ),
                            ...FormStatus.values.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.toString().split('.').last,
                                style: TextStyle(color: primaryColor),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value);
                            _searchForms();
                          },
                        ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading forms...',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFD32F2F)),
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadForms,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_forms.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightAccent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.contact_mail_rounded, size: 48, color: primaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'No forms found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Forms will appear here when users submit them',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Debug Info',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _debugInfoRow('Shelter Owner ID:', _shelterOwnerId),
                _debugInfoRow('Forms Count:', '${_forms.length}'),
                _debugInfoRow('Is Loading:', '$_isLoading'),
                _debugInfoRow('Search Query:', '"$_searchQuery"'),
                _debugInfoRow('Selected Type:', '$_selectedType'),
                _debugInfoRow('Selected Status:', '$_selectedStatus'),
                _debugInfoRow('Error:', '$_errorMessage'),
                const SizedBox(height: 16),
                Text(
                  'Forms:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
                ..._forms.map((form) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4),
                  child: Text(
                    '• ${form.subject} (${form.formType})',
                    style: TextStyle(color: primaryColor.withOpacity(0.8)),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _debugInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: primaryColor.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ContactVolunteerFormModel form) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: lightAccent.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Form Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTypeColor(form.formType).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor(form.formType).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getTypeIcon(form.formType),
                    color: _getTypeColor(form.formType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Form Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.subject,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${form.formTypeDisplayName} • From ${form.submitterName}',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        form.timeSinceSubmission,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(form.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(form.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    form.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(form.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Form Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightAccent.withOpacity(0.5), width: 1),
              ),
              child: Text(
                form.message,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFormDetails(form),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (form.isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRespondDialog(form),
                      icon: const Icon(Icons.reply_rounded, size: 18),
                      label: const Text('Respond'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateFormStatus(form.id, FormStatus.closed),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF757575),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
        return const Color(0xFF1976D2);
      case FormType.volunteer:
        return const Color(0xFF388E3C);
      case FormType.donation:
        return const Color(0xFFF57C00);
    }
  }

  IconData _getTypeIcon(FormType type) {
    switch (type) {
      case FormType.contact:
        return Icons.contact_mail_rounded;
      case FormType.volunteer:
        return Icons.volunteer_activism_rounded;
      case FormType.donation:
        return Icons.attach_money_rounded;
    }
  }

  Color _getStatusColor(FormStatus status) {
    switch (status) {
      case FormStatus.pending:
        return const Color(0xFFF57C00);
      case FormStatus.responded:
        return const Color(0xFF388E3C);
      case FormStatus.closed:
        return const Color(0xFF757575);
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
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Respond to Form',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightAccent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Respond to ${form.submitterName}\'s ${form.formTypeDisplayName.toLowerCase()} form?',
                  style: TextStyle(color: primaryColor, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightAccent, width: 1.5),
                ),
                child: TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'Your Response',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: primaryColor),
                  maxLines: 4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor.withOpacity(0.7),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateFormStatus(
                  form.id, 
                  FormStatus.responded,
                  response: responseController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Response'),
            ),
          ],
        );
      },
    );
  }
}