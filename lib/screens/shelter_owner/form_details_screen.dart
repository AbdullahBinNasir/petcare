import 'package:flutter/material.dart';
import '../../models/contact_volunteer_form_model.dart';

class FormDetailsScreen extends StatelessWidget {
  final ContactVolunteerFormModel form;

  const FormDetailsScreen({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                form.subject,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${form.formTypeDisplayName} • From ${form.submitterName}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted: ${form.timeSinceSubmission}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submitter Information
            _buildSectionCard(
              'Submitter Information',
              [
                _buildInfoRow('Name', form.submitterName),
                _buildInfoRow('Email', form.submitterEmail),
                _buildInfoRow('Phone', form.submitterPhone),
              ],
            ),

            const SizedBox(height: 16),

            // Form Message
            _buildSectionCard(
              'Message',
              [
                _buildInfoRow('Subject', form.subject),
                _buildInfoRow('Message', form.message),
              ],
            ),

            const SizedBox(height: 16),

            // Form-specific Information
            if (form.formType == FormType.volunteer) ...[
              _buildSectionCard(
                'Volunteer Information',
                [
                  if (form.volunteerInterests != null)
                    _buildInfoRow('Interests', form.volunteerInterests!),
                  if (form.availableDays != null)
                    _buildInfoRow('Available Days', form.availableDays!),
                  if (form.availableTimes != null)
                    _buildInfoRow('Available Times', form.availableTimes!),
                  if (form.skills != null)
                    _buildInfoRow('Skills', form.skills!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (form.formType == FormType.donation) ...[
              _buildSectionCard(
                'Donation Information',
                [
                  if (form.donationAmount != null)
                    _buildInfoRow('Amount', form.donationAmount!),
                  if (form.donationType != null)
                    _buildInfoRow('Type', form.donationType!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Response Information
            if (form.response != null) ...[
              _buildSectionCard(
                'Your Response',
                [
                  _buildInfoRow('Response', form.response!),
                  if (form.responseDate != null)
                    _buildInfoRow('Response Date', _formatDate(form.responseDate!)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
