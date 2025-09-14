import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../veterinarian/vet_appointment_completion_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUserModel;
    final isVet = currentUser?.role == UserRole.veterinarian;
    final canEdit = isVet || appointment.status == AppointmentStatus.scheduled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                if (appointment.status == AppointmentStatus.scheduled) ...[
                  const PopupMenuItem(
                    value: 'confirm',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Confirm'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel'),
                      ],
                    ),
                  ),
                ],
                if (isVet && appointment.status == AppointmentStatus.confirmed) ...[
                  const PopupMenuItem(
                    value: 'start',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Start Appointment'),
                      ],
                    ),
                  ),
                ],
                if (isVet && appointment.status == AppointmentStatus.inProgress) ...[
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.done, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Complete'),
                      ],
                    ),
                  ),
                ],
                if (isVet && (appointment.status == AppointmentStatus.scheduled || 
                              appointment.status == AppointmentStatus.confirmed)) ...[
                  const PopupMenuItem(
                    value: 'complete_detailed',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Complete with Medical Details'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            if (appointment.diagnosis != null || 
                appointment.treatment != null || 
                appointment.prescription != null) ...[
              const SizedBox(height: 16),
              _buildMedicalInfoCard(),
            ],
            if (appointment.cost != null) ...[
              const SizedBox(height: 16),
              _buildCostCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(appointment.status),
                color: _getStatusColor(appointment.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(appointment.status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy at hh:mm a').format(appointment.updatedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMMM dd, yyyy').format(appointment.appointmentDate),
            ),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              appointment.timeSlot,
            ),
            _buildInfoRow(
              Icons.medical_services,
              'Type',
              _getTypeText(appointment.type),
            ),
            _buildInfoRow(
              Icons.pets,
              'Pet ID',
              appointment.petId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailSection('Reason for Visit', appointment.reason),
            if (appointment.notes != null)
              _buildDetailSection('Notes', appointment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (appointment.diagnosis != null)
              _buildDetailSection('Diagnosis', appointment.diagnosis!),
            if (appointment.treatment != null)
              _buildDetailSection('Treatment', appointment.treatment!),
            if (appointment.prescription != null)
              _buildDetailSection('Prescription', appointment.prescription!),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.attach_money, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Cost:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '\$${appointment.cost!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final notificationService = NotificationService();

    try {
      switch (action) {
        case 'confirm':
          await appointmentService.confirmAppointment(appointment.id);
          await notificationService.scheduleAppointmentReminder(appointment);
          _showSnackBar(context, 'Appointment confirmed and reminders set!');
          break;
        case 'cancel':
          await appointmentService.cancelAppointment(appointment.id);
          await notificationService.cancelAppointmentReminders(appointment.id);
          _showSnackBar(context, 'Appointment cancelled');
          break;
        case 'start':
          final updatedAppointment = appointment.copyWith(
            status: AppointmentStatus.inProgress,
            updatedAt: DateTime.now(),
          );
          await appointmentService.updateAppointment(updatedAppointment);
          _showSnackBar(context, 'Appointment started');
          break;
        case 'complete':
          await appointmentService.completeAppointment(
            appointmentId: appointment.id,
            diagnosis: 'Completed via app',
          );
          _showSnackBar(context, 'Appointment completed');
          break;
        case 'complete_detailed':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VetAppointmentCompletionScreen(appointment: appointment),
            ),
          ).then((_) {
            // Refresh the screen if needed
            Navigator.pop(context);
          });
          break;
        case 'edit':
          // Navigate to edit screen
          _showSnackBar(context, 'Edit functionality coming soon');
          break;
      }
    } catch (e) {
      _showSnackBar(context, 'Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.teal;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.play_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  String _getTypeText(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return 'Check-up';
      case AppointmentType.vaccination:
        return 'Vaccination';
      case AppointmentType.surgery:
        return 'Surgery';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.grooming:
        return 'Grooming';
      case AppointmentType.consultation:
        return 'Consultation';
    }
  }
}
