import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/contact_submission_service.dart';
import '../../models/contact_submission_model.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() => _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactSubmissionService>(context, listen: false).loadSubmissions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ContactSubmissionService>(context, listen: false).loadSubmissions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<ContactSubmissionService>(context, listen: false)
                            .searchSubmissions('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              Provider.of<ContactSubmissionService>(context, listen: false)
                  .searchSubmissions(value);
            },
          ),
          const SizedBox(height: 12),
          _buildStatusFilters(),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Consumer<ContactSubmissionService>(
      builder: (context, contactService, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', null, contactService.selectedStatus),
              const SizedBox(width: 8),
              ...ContactStatus.values.map((status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      status.displayName,
                      status,
                      contactService.selectedStatus,
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ContactStatus? status, ContactStatus? selectedStatus) {
    final isSelected = selectedStatus == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        Provider.of<ContactSubmissionService>(context, listen: false)
            .filterByStatus(selected ? status : null);
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildContactsList() {
    return Consumer<ContactSubmissionService>(
      builder: (context, contactService, child) {
        if (contactService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = contactService.filteredSubmissions;

        if (contacts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return _buildContactCard(contact);
          },
        );
      },
    );
  }

  Widget _buildContactCard(ContactSubmission contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(contact.status).withOpacity(0.1),
          child: Icon(
            Icons.contact_support,
            color: _getStatusColor(contact.status),
          ),
        ),
        title: Text(
          contact.subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${contact.name} (${contact.email})'),
            Text('Status: ${contact.statusDisplayName}'),
            Text('Submitted: ${_formatDate(contact.submittedAt)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(contact.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            contact.statusDisplayName,
            style: TextStyle(
              color: _getStatusColor(contact.status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(contact.message),
                const SizedBox(height: 16),
                if (contact.adminNotes != null) ...[
                  Text(
                    'Admin Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(contact.adminNotes!),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showUpdateStatusDialog(contact),
                        icon: const Icon(Icons.edit),
                        label: const Text('Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showContactDetails(contact),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_support_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Contact Submissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No contact form submissions found matching your criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(ContactSubmission contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Contact: ${contact.subject}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContactStatus>(
              value: contact.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ContactStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  Provider.of<ContactSubmissionService>(context, listen: false)
                      .updateSubmissionStatus(
                    contact.id,
                    newStatus,
                    adminNotes: 'Status updated by admin',
                    resolvedBy: 'Admin',
                  );
                  Navigator.pop(context);
                }
              },
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

  void _showContactDetails(ContactSubmission contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', contact.subject),
              _buildDetailRow('Name', contact.name),
              _buildDetailRow('Email', contact.email),
              _buildDetailRow('Status', contact.statusDisplayName),
              _buildDetailRow('Submitted', _formatDate(contact.submittedAt)),
              if (contact.resolvedBy != null)
                _buildDetailRow('Resolved By', contact.resolvedBy!),
              if (contact.resolvedAt != null)
                _buildDetailRow('Resolved At', _formatDate(contact.resolvedAt!)),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(contact.message),
              if (contact.adminNotes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Admin Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(contact.adminNotes!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Colors.orange;
      case ContactStatus.inProgress:
        return Colors.blue;
      case ContactStatus.resolved:
        return Colors.green;
      case ContactStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
