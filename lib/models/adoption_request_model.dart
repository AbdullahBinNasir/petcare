import 'package:cloud_firestore/cloud_firestore.dart';

enum AdoptionRequestStatus { pending, approved, rejected, cancelled, completed }

class AdoptionRequestModel {
  final String id;
  final String petListingId;
  final String petOwnerId;
  final String shelterOwnerId;
  final String petOwnerName;
  final String petOwnerEmail;
  final String petOwnerPhone;
  final String petName;
  final String petType;
  final String reasonForAdoption;
  final String livingSituation;
  final String experienceWithPets;
  final bool hasOtherPets;
  final String? otherPetsDescription;
  final bool hasChildren;
  final String? childrenAges;
  final String? homeDescription;
  final String? workSchedule;
  final String? additionalNotes;
  final AdoptionRequestStatus status;
  final String? shelterResponse;
  final DateTime? responseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AdoptionRequestModel({
    required this.id,
    required this.petListingId,
    required this.petOwnerId,
    required this.shelterOwnerId,
    required this.petOwnerName,
    required this.petOwnerEmail,
    required this.petOwnerPhone,
    required this.petName,
    required this.petType,
    required this.reasonForAdoption,
    required this.livingSituation,
    required this.experienceWithPets,
    this.hasOtherPets = false,
    this.otherPetsDescription,
    this.hasChildren = false,
    this.childrenAges,
    this.homeDescription,
    this.workSchedule,
    this.additionalNotes,
    this.status = AdoptionRequestStatus.pending,
    this.shelterResponse,
    this.responseDate,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AdoptionRequestModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return AdoptionRequestModel(
        id: doc.id,
        petListingId: data['petListingId'] ?? '',
        petOwnerId: data['petOwnerId'] ?? '',
        shelterOwnerId: data['shelterOwnerId'] ?? '',
        petOwnerName: data['petOwnerName'] ?? '',
        petOwnerEmail: data['petOwnerEmail'] ?? '',
        petOwnerPhone: data['petOwnerPhone'] ?? '',
        petName: data['petName'] ?? '',
        petType: data['petType'] ?? '',
        reasonForAdoption: data['reasonForAdoption'] ?? '',
        livingSituation: data['livingSituation'] ?? '',
        experienceWithPets: data['experienceWithPets'] ?? '',
        hasOtherPets: data['hasOtherPets'] ?? false,
        otherPetsDescription: data['otherPetsDescription'],
        hasChildren: data['hasChildren'] ?? false,
        childrenAges: data['childrenAges'],
        homeDescription: data['homeDescription'],
        workSchedule: data['workSchedule'],
        additionalNotes: data['additionalNotes'],
        status: _parseStatus(data['status']),
        shelterResponse: data['shelterResponse'],
        responseDate: data['responseDate'] != null 
            ? (data['responseDate'] as Timestamp).toDate() 
            : null,
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('Error parsing adoption request from Firestore: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static AdoptionRequestStatus _parseStatus(dynamic status) {
    if (status == null) return AdoptionRequestStatus.pending;
    
    try {
      return AdoptionRequestStatus.values.firstWhere(
        (e) => e.toString() == 'AdoptionRequestStatus.$status',
      );
    } catch (e) {
      print('Error parsing status: $status, defaulting to pending');
      return AdoptionRequestStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petListingId': petListingId,
      'petOwnerId': petOwnerId,
      'shelterOwnerId': shelterOwnerId,
      'petOwnerName': petOwnerName,
      'petOwnerEmail': petOwnerEmail,
      'petOwnerPhone': petOwnerPhone,
      'petName': petName,
      'petType': petType,
      'reasonForAdoption': reasonForAdoption,
      'livingSituation': livingSituation,
      'experienceWithPets': experienceWithPets,
      'hasOtherPets': hasOtherPets,
      'otherPetsDescription': otherPetsDescription,
      'hasChildren': hasChildren,
      'childrenAges': childrenAges,
      'homeDescription': homeDescription,
      'workSchedule': workSchedule,
      'additionalNotes': additionalNotes,
      'status': status.toString().split('.').last,
      'shelterResponse': shelterResponse,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case AdoptionRequestStatus.pending:
        return 'Pending';
      case AdoptionRequestStatus.approved:
        return 'Approved';
      case AdoptionRequestStatus.rejected:
        return 'Rejected';
      case AdoptionRequestStatus.cancelled:
        return 'Cancelled';
      case AdoptionRequestStatus.completed:
        return 'Completed';
    }
  }

  bool get isPending => status == AdoptionRequestStatus.pending;
  bool get isApproved => status == AdoptionRequestStatus.approved;
  bool get isRejected => status == AdoptionRequestStatus.rejected;
  bool get isCompleted => status == AdoptionRequestStatus.completed;

  AdoptionRequestModel copyWith({
    String? petOwnerName,
    String? petOwnerEmail,
    String? petOwnerPhone,
    String? reasonForAdoption,
    String? livingSituation,
    String? experienceWithPets,
    bool? hasOtherPets,
    String? otherPetsDescription,
    bool? hasChildren,
    String? childrenAges,
    String? homeDescription,
    String? workSchedule,
    String? additionalNotes,
    AdoptionRequestStatus? status,
    String? shelterResponse,
    DateTime? responseDate,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AdoptionRequestModel(
      id: id,
      petListingId: petListingId,
      petOwnerId: petOwnerId,
      shelterOwnerId: shelterOwnerId,
      petOwnerName: petOwnerName ?? this.petOwnerName,
      petOwnerEmail: petOwnerEmail ?? this.petOwnerEmail,
      petOwnerPhone: petOwnerPhone ?? this.petOwnerPhone,
      petName: petName,
      petType: petType,
      reasonForAdoption: reasonForAdoption ?? this.reasonForAdoption,
      livingSituation: livingSituation ?? this.livingSituation,
      experienceWithPets: experienceWithPets ?? this.experienceWithPets,
      hasOtherPets: hasOtherPets ?? this.hasOtherPets,
      otherPetsDescription: otherPetsDescription ?? this.otherPetsDescription,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenAges: childrenAges ?? this.childrenAges,
      homeDescription: homeDescription ?? this.homeDescription,
      workSchedule: workSchedule ?? this.workSchedule,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      shelterResponse: shelterResponse ?? this.shelterResponse,
      responseDate: responseDate ?? this.responseDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AdoptionRequestModel(id: $id, petName: $petName, petOwnerName: $petOwnerName, status: $status)';
  }
}
