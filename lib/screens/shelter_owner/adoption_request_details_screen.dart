import 'package:flutter/material.dart';
import '../../models/adoption_request_model.dart';

class AdoptionRequestDetailsScreen extends StatelessWidget {
  final AdoptionRequestModel adoptionRequest;

  const AdoptionRequestDetailsScreen({
    super.key,
    required this.adoptionRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Request Details'),
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
                        Expanded(
                          child: Text(
                            adoptionRequest.petName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(adoptionRequest.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            adoptionRequest.statusDisplayName,
                            style: TextStyle(
                              color: _getStatusColor(adoptionRequest.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${adoptionRequest.petType} • Requested by ${adoptionRequest.petOwnerName}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatDate(adoptionRequest.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Adopter Information
            _buildSectionCard(
              'Adopter Information',
              [
                _buildInfoRow('Name', adoptionRequest.petOwnerName),
                _buildInfoRow('Email', adoptionRequest.petOwnerEmail),
                _buildInfoRow('Phone', adoptionRequest.petOwnerPhone),
              ],
            ),

            const SizedBox(height: 16),

            // Adoption Details
            _buildSectionCard(
              'Adoption Details',
              [
                _buildInfoRow('Pet Name', adoptionRequest.petName),
                _buildInfoRow('Pet Type', adoptionRequest.petType),
                _buildInfoRow('Reason for Adoption', adoptionRequest.reasonForAdoption),
                _buildInfoRow('Living Situation', adoptionRequest.livingSituation),
                _buildInfoRow('Experience with Pets', adoptionRequest.experienceWithPets),
              ],
            ),

            const SizedBox(height: 16),

            // Home Environment
            _buildSectionCard(
              'Home Environment',
              [
                _buildInfoRow('Has Other Pets', adoptionRequest.hasOtherPets ? 'Yes' : 'No'),
                if (adoptionRequest.hasOtherPets && adoptionRequest.otherPetsDescription != null)
                  _buildInfoRow('Other Pets Description', adoptionRequest.otherPetsDescription!),
                _buildInfoRow('Has Children', adoptionRequest.hasChildren ? 'Yes' : 'No'),
                if (adoptionRequest.hasChildren && adoptionRequest.childrenAges != null)
                  _buildInfoRow('Children Ages', adoptionRequest.childrenAges!),
                if (adoptionRequest.homeDescription != null)
                  _buildInfoRow('Home Description', adoptionRequest.homeDescription!),
                if (adoptionRequest.workSchedule != null)
                  _buildInfoRow('Work Schedule', adoptionRequest.workSchedule!),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Information
            if (adoptionRequest.additionalNotes != null && adoptionRequest.additionalNotes!.isNotEmpty)
              _buildSectionCard(
                'Additional Notes',
                [
                  _buildInfoRow('Notes', adoptionRequest.additionalNotes!),
                ],
              ),

            const SizedBox(height: 16),

            // Shelter Response
            if (adoptionRequest.shelterResponse != null)
              _buildSectionCard(
                'Shelter Response',
                [
                  _buildInfoRow('Response', adoptionRequest.shelterResponse!),
                  if (adoptionRequest.responseDate != null)
                    _buildInfoRow('Response Date', _formatDate(adoptionRequest.responseDate!)),
                ],
              ),

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
}
