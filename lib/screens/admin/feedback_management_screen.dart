import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/feedback_submission_service.dart';
import '../../models/feedback_submission_model.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackSubmissionService>(context, listen: false).loadSubmissions();
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
        title: const Text('Feedback Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<FeedbackSubmissionService>(context, listen: false).loadSubmissions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildFeedbackList()),
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
              hintText: 'Search feedback...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<FeedbackSubmissionService>(context, listen: false)
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
              Provider.of<FeedbackSubmissionService>(context, listen: false)
                  .searchSubmissions(value);
            },
          ),
          const SizedBox(height: 12),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<FeedbackSubmissionService>(
      builder: (context, feedbackService, child) {
        return Column(
          children: [
            // Status filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Status', null, feedbackService.selectedStatus, 'status'),
                  const SizedBox(width: 8),
                  ...FeedbackStatus.values.map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          status.displayName,
                          status,
                          feedbackService.selectedStatus,
                          'status',
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Type filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Types', null, feedbackService.selectedType, 'type'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Suggestion', 'suggestion', feedbackService.selectedType, 'type'),
                  _buildFilterChip('Bug Report', 'bug', feedbackService.selectedType, 'type'),
                  _buildFilterChip('Feature Request', 'feature', feedbackService.selectedType, 'type'),
                  _buildFilterChip('General', 'general', feedbackService.selectedType, 'type'),
                  _buildFilterChip('Complaint', 'complaint', feedbackService.selectedType, 'type'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, dynamic value, dynamic selectedValue, String filterType) {
    final isSelected = selectedValue == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (filterType == 'status') {
          Provider.of<FeedbackSubmissionService>(context, listen: false)
              .filterByStatus(selected ? value : null);
        } else if (filterType == 'type') {
          Provider.of<FeedbackSubmissionService>(context, listen: false)
              .filterByType(selected ? value : null);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildFeedbackList() {
    return Consumer<FeedbackSubmissionService>(
      builder: (context, feedbackService, child) {
        if (feedbackService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbacks = feedbackService.filteredSubmissions;

        if (feedbacks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            return _buildFeedbackCard(feedback);
          },
        );
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackSubmission feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(feedback.status).withOpacity(0.1),
          child: Icon(
            Icons.feedback,
            color: _getStatusColor(feedback.status),
          ),
        ),
        title: Text(
          feedback.subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${feedback.feedbackTypeDisplayName}'),
            Text('Rating: ${'★' * feedback.rating}${'☆' * (5 - feedback.rating)}'),
            Text('Status: ${feedback.statusDisplayName}'),
            Text('Submitted: ${_formatDate(feedback.submittedAt)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(feedback.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            feedback.statusDisplayName,
            style: TextStyle(
              color: _getStatusColor(feedback.status),
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(feedback.name ?? 'Anonymous'),
                          if (feedback.email != null) Text(feedback.email!),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRatingColor(feedback.rating).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${'★' * feedback.rating}',
                        style: TextStyle(
                          color: _getRatingColor(feedback.rating),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Feedback:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(feedback.message),
                if (feedback.adminResponse != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Admin Response:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(feedback.adminResponse!),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showUpdateStatusDialog(feedback),
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
                        onPressed: () => _showFeedbackDetails(feedback),
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
            Icons.feedback_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Feedback Submissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No feedback submissions found matching your criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(FeedbackSubmission feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Feedback: ${feedback.subject}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeedbackStatus>(
              value: feedback.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: FeedbackStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  Provider.of<FeedbackSubmissionService>(context, listen: false)
                      .updateSubmissionStatus(
                    feedback.id,
                    newStatus,
                    respondedBy: 'Admin',
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

  void _showFeedbackDetails(FeedbackSubmission feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', feedback.subject),
              _buildDetailRow('Type', feedback.feedbackTypeDisplayName),
              _buildDetailRow('Rating', '${'★' * feedback.rating}${'☆' * (5 - feedback.rating)}'),
              _buildDetailRow('Status', feedback.statusDisplayName),
              _buildDetailRow('Submitted', _formatDate(feedback.submittedAt)),
              if (feedback.name != null) _buildDetailRow('Name', feedback.name!),
              if (feedback.email != null) _buildDetailRow('Email', feedback.email!),
              if (feedback.respondedBy != null)
                _buildDetailRow('Responded By', feedback.respondedBy!),
              if (feedback.respondedAt != null)
                _buildDetailRow('Responded At', _formatDate(feedback.respondedAt!)),
              const SizedBox(height: 16),
              const Text(
                'Feedback:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(feedback.message),
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Admin Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(feedback.adminResponse!),
                ),
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

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Colors.orange;
      case FeedbackStatus.reviewed:
        return Colors.blue;
      case FeedbackStatus.acknowledged:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
