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
      backgroundColor: const Color(0xFFFAFAF0),
      appBar: AppBar(
        title: const Text(
          'Adoption Request Details',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7D4D20),
                    const Color(0xFF7D4D20).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7D4D20).withOpacity(0.2),
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
                        Expanded(
                          child: Text(
                            adoptionRequest.petName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFAFAF0),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(adoptionRequest.status),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            adoptionRequest.statusDisplayName,
                            style: const TextStyle(
                              color: Color(0xFFFAFAF0),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAF0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${adoptionRequest.petType} • Requested by ${adoptionRequest.petOwnerName}',
                        style: const TextStyle(
                          color: Color(0xFFFAFAF0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted: ${_formatDate(adoptionRequest.createdAt)}',
                      style: TextStyle(
                        color: const Color(0xFFFAFAF0).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Adopter Information
            _buildSectionCard(
              'Adopter Information',
              Icons.person_outline_rounded,
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
              Icons.pets_rounded,
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
              Icons.home_outlined,
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
                Icons.note_outlined,
                [
                  _buildInfoRow('Notes', adoptionRequest.additionalNotes!),
                ],
              ),

            const SizedBox(height: 16),

            // Shelter Response
            if (adoptionRequest.shelterResponse != null)
              _buildSectionCard(
                'Shelter Response',
                Icons.message_outlined,
                [
                  _buildInfoRow('Response', adoptionRequest.shelterResponse!),
                  if (adoptionRequest.responseDate != null)
                    _buildInfoRow('Response Date', _formatDate(adoptionRequest.responseDate!)),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D4D20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7D4D20),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7D4D20),
                    letterSpacing: 0.3,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7D4D20).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7D4D20),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF7D4D20).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
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
}