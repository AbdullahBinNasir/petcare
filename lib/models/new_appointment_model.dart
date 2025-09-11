import 'package:cloud_firestore/cloud_firestore.dart';

// Appointment status enum
enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow
}

// Appointment type enum
enum AppointmentType {
  checkup,
  vaccination,
  surgery,
  emergency,
  grooming,
  consultation,
  followUp
}

class NewAppointmentModel {
  final String id;
  final String petOwnerId;
  final String petId;
  final String veterinarianId;
  final DateTime appointmentDate;
  final String timeSlot;
  final AppointmentType type;
  final AppointmentStatus status;
  final String reason;
  final String? notes;
  final String? medicalConcerns;
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // Additional fields for enhanced functionality
  final String? reminderSent;
  final Map<String, dynamic>? metadata;

  const NewAppointmentModel({
    required this.id,
    required this.petOwnerId,
    required this.petId,
    required this.veterinarianId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.type,
    this.status = AppointmentStatus.scheduled,
    required this.reason,
    this.notes,
    this.medicalConcerns,
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.reminderSent,
    this.metadata,
  });

  // Factory constructor from Firestore
  factory NewAppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NewAppointmentModel(
      id: doc.id,
      petOwnerId: data['petOwnerId'] as String? ?? '',
      petId: data['petId'] as String? ?? '',
      veterinarianId: data['veterinarianId'] as String? ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      type: _parseAppointmentType(data['type']),
      status: _parseAppointmentStatus(data['status']),
      reason: data['reason'] as String? ?? '',
      notes: data['notes'] as String?,
      medicalConcerns: data['medicalConcerns'] as String?,
      diagnosis: data['diagnosis'] as String?,
      treatment: data['treatment'] as String?,
      prescription: data['prescription'] as String?,
      cost: (data['cost'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      reminderSent: data['reminderSent'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'petOwnerId': petOwnerId,
      'petId': petId,
      'veterinarianId': veterinarianId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'type': _appointmentTypeToString(type),
      'status': _appointmentStatusToString(status),
      'reason': reason,
      'notes': notes,
      'medicalConcerns': medicalConcerns,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'cost': cost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'reminderSent': reminderSent,
      'metadata': metadata,
    };
  }

  // Safe enum parsing for AppointmentType
  static AppointmentType _parseAppointmentType(dynamic value) {
    if (value == null) return AppointmentType.checkup;
    
    final stringValue = value.toString().toLowerCase();
    
    switch (stringValue) {
      case 'checkup':
        return AppointmentType.checkup;
      case 'vaccination':
        return AppointmentType.vaccination;
      case 'surgery':
        return AppointmentType.surgery;
      case 'emergency':
        return AppointmentType.emergency;
      case 'grooming':
        return AppointmentType.grooming;
      case 'consultation':
        return AppointmentType.consultation;
      case 'followup':
      case 'follow_up':
        return AppointmentType.followUp;
      default:
        return AppointmentType.checkup;
    }
  }

  // Safe enum parsing for AppointmentStatus
  static AppointmentStatus _parseAppointmentStatus(dynamic value) {
    if (value == null) return AppointmentStatus.scheduled;
    
    final stringValue = value.toString().toLowerCase();
    
    switch (stringValue) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'inprogress':
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'noshow':
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  // Convert AppointmentType to string
  static String _appointmentTypeToString(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return 'checkup';
      case AppointmentType.vaccination:
        return 'vaccination';
      case AppointmentType.surgery:
        return 'surgery';
      case AppointmentType.emergency:
        return 'emergency';
      case AppointmentType.grooming:
        return 'grooming';
      case AppointmentType.consultation:
        return 'consultation';
      case AppointmentType.followUp:
        return 'followup';
    }
  }

  // Convert AppointmentStatus to string
  static String _appointmentStatusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.inProgress:
        return 'inprogress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'noshow';
    }
  }

  // Helper methods
  bool get isUpcoming => appointmentDate.isAfter(DateTime.now()) && 
      status != AppointmentStatus.cancelled && 
      status != AppointmentStatus.completed &&
      status != AppointmentStatus.noShow;

  bool get isPast => appointmentDate.isBefore(DateTime.now()) || 
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.noShow;

  bool get canBeCancelled => isUpcoming && 
      status != AppointmentStatus.inProgress;

  bool get canBeConfirmed => status == AppointmentStatus.scheduled;

  String get statusDisplayName {
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

  String get typeDisplayName {
    switch (type) {
      case AppointmentType.checkup:
        return 'Checkup';
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
      case AppointmentType.followUp:
        return 'Follow-up';
    }
  }

  // CopyWith method
  NewAppointmentModel copyWith({
    String? id,
    String? petOwnerId,
    String? petId,
    String? veterinarianId,
    DateTime? appointmentDate,
    String? timeSlot,
    AppointmentType? type,
    AppointmentStatus? status,
    String? reason,
    String? notes,
    String? medicalConcerns,
    String? diagnosis,
    String? treatment,
    String? prescription,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? reminderSent,
    Map<String, dynamic>? metadata,
  }) {
    return NewAppointmentModel(
      id: id ?? this.id,
      petOwnerId: petOwnerId ?? this.petOwnerId,
      petId: petId ?? this.petId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      medicalConcerns: medicalConcerns ?? this.medicalConcerns,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      reminderSent: reminderSent ?? this.reminderSent,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'NewAppointmentModel(id: $id, petOwnerId: $petOwnerId, appointmentDate: $appointmentDate, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewAppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
