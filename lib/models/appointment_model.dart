import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum AppointmentType {
  checkup,
  vaccination,
  surgery,
  emergency,
  grooming,
  consultation,
}

class AppointmentModel {
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
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
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
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      petOwnerId: data['petOwnerId'] ?? '',
      petId: data['petId'] ?? '',
      veterinarianId: data['veterinarianId'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      type: AppointmentType.values.firstWhere(
        (e) => e.toString() == 'AppointmentType.${data['type']}',
        orElse: () => AppointmentType.checkup,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${data['status']}',
        orElse: () => AppointmentStatus.scheduled,
      ),
      reason: data['reason'] ?? '',
      notes: data['notes'],
      diagnosis: data['diagnosis'],
      treatment: data['treatment'],
      prescription: data['prescription'],
      cost: data['cost']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petOwnerId': petOwnerId,
      'petId': petId,
      'veterinarianId': veterinarianId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'type': _enumToString(type),
      'status': _enumToString(status),
      'reason': reason,
      'notes': notes,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'cost': cost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String _enumToString(dynamic enumValue) {
    if (enumValue == null) return '';

    final enumString = enumValue.toString();
    final parts = enumString.split('.');

    // Ensure we have at least one part and return the last part
    if (parts.isNotEmpty && parts.length > 1) {
      return parts.last;
    }

    // Fallback: return the original string or handle specific enum types
    if (enumValue is AppointmentType) {
      switch (enumValue) {
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
      }
    }

    if (enumValue is AppointmentStatus) {
      switch (enumValue) {
        case AppointmentStatus.scheduled:
          return 'scheduled';
        case AppointmentStatus.confirmed:
          return 'confirmed';
        case AppointmentStatus.inProgress:
          return 'inProgress';
        case AppointmentStatus.completed:
          return 'completed';
        case AppointmentStatus.cancelled:
          return 'cancelled';
        case AppointmentStatus.noShow:
          return 'noShow';
      }
    }

    // Final fallback
    return enumString.contains('.') ? enumString.split('.').last : enumString;
  }

  // Test method to validate enum conversion
  static void testEnumConversion() {
    final model = AppointmentModel(
      id: 'test',
      petOwnerId: 'test',
      petId: 'test',
      veterinarianId: 'test',
      appointmentDate: DateTime.now(),
      timeSlot: '10:00',
      type: AppointmentType.checkup,
      reason: 'test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print(
      'Type conversion test: ${model._enumToString(AppointmentType.checkup)}',
    );
    print(
      'Status conversion test: ${model._enumToString(AppointmentStatus.scheduled)}',
    );
    print('Firestore data: ${model.toFirestore()}');
  }

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) &&
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed;

  bool get isPast =>
      appointmentDate.isBefore(DateTime.now()) ||
      status == AppointmentStatus.completed;

  AppointmentModel copyWith({
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
    String? diagnosis,
    String? treatment,
    String? prescription,
    double? cost,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
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
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      cost: cost ?? this.cost,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
