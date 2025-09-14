import 'package:cloud_firestore/cloud_firestore.dart';

enum HealthRecordType { vaccination, medication, checkup, surgery, allergy, injury, other }

class HealthRecordModel {
  final String id;
  final String petId;
  final String veterinarianId;
  final HealthRecordType type;
  final String title;
  final String description;
  final DateTime recordDate;
  final DateTime? nextDueDate;
  final String? medication;
  final String? dosage;
  final String? notes;
  final String? diagnosis;
  final String? prescription;
  final String? treatmentNotes;
  final List<String> attachmentUrls;
  final List<String> fileAttachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  HealthRecordModel({
    required this.id,
    required this.petId,
    required this.veterinarianId,
    required this.type,
    required this.title,
    required this.description,
    required this.recordDate,
    this.nextDueDate,
    this.medication,
    this.dosage,
    this.notes,
    this.diagnosis,
    this.prescription,
    this.treatmentNotes,
    this.attachmentUrls = const [],
    this.fileAttachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory HealthRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthRecordModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      veterinarianId: data['veterinarianId'] ?? '',
      type: HealthRecordType.values.firstWhere(
        (e) => e.toString() == 'HealthRecordType.${data['type']}',
        orElse: () => HealthRecordType.other,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      recordDate: (data['recordDate'] as Timestamp).toDate(),
      nextDueDate: data['nextDueDate'] != null 
          ? (data['nextDueDate'] as Timestamp).toDate() 
          : null,
      medication: data['medication'],
      dosage: data['dosage'],
      notes: data['notes'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      treatmentNotes: data['treatmentNotes'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      fileAttachments: List<String>.from(data['fileAttachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'veterinarianId': veterinarianId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'recordDate': Timestamp.fromDate(recordDate),
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'medication': medication,
      'dosage': dosage,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'treatmentNotes': treatmentNotes,
      'attachmentUrls': attachmentUrls,
      'fileAttachments': fileAttachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  bool get isDue {
    if (nextDueDate == null) return false;
    return nextDueDate!.isBefore(DateTime.now().add(const Duration(days: 7)));
  }

  bool get isOverdue {
    if (nextDueDate == null) return false;
    return nextDueDate!.isBefore(DateTime.now());
  }

  HealthRecordModel copyWith({
    String? veterinarianId,
    HealthRecordType? type,
    String? title,
    String? description,
    DateTime? recordDate,
    DateTime? nextDueDate,
    String? medication,
    String? dosage,
    String? notes,
    List<String>? attachmentUrls,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return HealthRecordModel(
      id: id,
      petId: petId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      recordDate: recordDate ?? this.recordDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      medication: medication ?? this.medication,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
