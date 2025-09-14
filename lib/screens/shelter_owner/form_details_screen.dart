import 'package:flutter/material.dart';
import '../../models/contact_volunteer_form_model.dart';

class FormDetailsScreen extends StatelessWidget {
  final ContactVolunteerFormModel form;

  const FormDetailsScreen({
    super.key,
    required this.form,
  });

  // Custom color scheme
  static const Color primaryBrown = Color(0xFF7D4D20);
  static const Color creamBackground = Color(0xFFFAFAF0);
  static const Color lightBrown = Color(0xFF9D6B40);
  static const Color darkBrown = Color(0xFF5D3518);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text('Form Details'),
        backgroundColor: primaryBrown,
        foregroundColor: creamBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: primaryBrown.withOpacity(0.1), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                form.subject,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${form.formTypeDisplayName} • From ${form.submitterName}',
                                style: TextStyle(
                                  color: primaryBrown.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Submitted: ${form.timeSinceSubmission}',
                        style: TextStyle(
                          color: primaryBrown.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submitter Information
            _buildSectionCard(
              'Submitter Information',
              Icons.person,
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
              Icons.message,
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
                Icons.volunteer_activism,
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
                Icons.attach_money,
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
                Icons.reply,
                [
                  _buildInfoRow('Response', form.response!),
                  if (form.responseDate != null)
                    _buildInfoRow('Response Date', _formatDate(form.responseDate!)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryBrown.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryBrown,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: creamBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryBrown.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryBrown,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: darkBrown.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(FormType type) {
    switch (type) {
      case FormType.contact:
        return const Color(0xFF4A90E2); // Blue
      case FormType.volunteer:
        return const Color(0xFF7ED321); // Green
      case FormType.donation:
        return const Color(0xFFF5A623); // Orange
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
        return const Color(0xFFF5A623); // Orange
      case FormStatus.responded:
        return const Color(0xFF7ED321); // Green
      case FormStatus.closed:
        return primaryBrown; // Brown for closed status
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}