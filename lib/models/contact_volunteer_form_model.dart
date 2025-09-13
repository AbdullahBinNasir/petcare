import 'package:cloud_firestore/cloud_firestore.dart';

enum FormType { contact, volunteer, donation }
enum FormStatus { pending, responded, closed }

class ContactVolunteerFormModel {
  final String id;
  final String shelterOwnerId;
  final String submitterName;
  final String submitterEmail;
  final String submitterPhone;
  final FormType formType;
  final String subject;
  final String message;
  final String? volunteerInterests;
  final String? availableDays;
  final String? availableTimes;
  final String? skills;
  final String? donationAmount;
  final String? donationType;
  final FormStatus status;
  final String? response;
  final DateTime? responseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ContactVolunteerFormModel({
    required this.id,
    required this.shelterOwnerId,
    required this.submitterName,
    required this.submitterEmail,
    required this.submitterPhone,
    required this.formType,
    required this.subject,
    required this.message,
    this.volunteerInterests,
    this.availableDays,
    this.availableTimes,
    this.skills,
    this.donationAmount,
    this.donationType,
    this.status = FormStatus.pending,
    this.response,
    this.responseDate,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ContactVolunteerFormModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return ContactVolunteerFormModel(
        id: doc.id,
        shelterOwnerId: data['shelterOwnerId'] ?? '',
        submitterName: data['submitterName'] ?? '',
        submitterEmail: data['submitterEmail'] ?? '',
        submitterPhone: data['submitterPhone'] ?? '',
        formType: _parseFormType(data['formType']),
        subject: data['subject'] ?? '',
        message: data['message'] ?? '',
        volunteerInterests: data['volunteerInterests'],
        availableDays: data['availableDays'],
        availableTimes: data['availableTimes'],
        skills: data['skills'],
        donationAmount: data['donationAmount'],
        donationType: data['donationType'],
        status: _parseStatus(data['status']),
        response: data['response'],
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
      print('Error parsing contact/volunteer form from Firestore: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static FormType _parseFormType(dynamic formType) {
    if (formType == null) return FormType.contact;
    
    try {
      return FormType.values.firstWhere(
        (e) => e.toString() == 'FormType.$formType',
      );
    } catch (e) {
      print('Error parsing form type: $formType, defaulting to contact');
      return FormType.contact;
    }
  }

  static FormStatus _parseStatus(dynamic status) {
    if (status == null) return FormStatus.pending;
    
    try {
      return FormStatus.values.firstWhere(
        (e) => e.toString() == 'FormStatus.$status',
      );
    } catch (e) {
      print('Error parsing status: $status, defaulting to pending');
      return FormStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shelterOwnerId': shelterOwnerId,
      'submitterName': submitterName,
      'submitterEmail': submitterEmail,
      'submitterPhone': submitterPhone,
      'formType': formType.toString().split('.').last,
      'subject': subject,
      'message': message,
      'volunteerInterests': volunteerInterests,
      'availableDays': availableDays,
      'availableTimes': availableTimes,
      'skills': skills,
      'donationAmount': donationAmount,
      'donationType': donationType,
      'status': status.toString().split('.').last,
      'response': response,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  String get formTypeDisplayName {
    switch (formType) {
      case FormType.contact:
        return 'Contact';
      case FormType.volunteer:
        return 'Volunteer';
      case FormType.donation:
        return 'Donation';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case FormStatus.pending:
        return 'Pending';
      case FormStatus.responded:
        return 'Responded';
      case FormStatus.closed:
        return 'Closed';
    }
  }

  bool get isPending => status == FormStatus.pending;
  bool get isResponded => status == FormStatus.responded;
  bool get isClosed => status == FormStatus.closed;

  String get timeSinceSubmission {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }

  ContactVolunteerFormModel copyWith({
    String? submitterName,
    String? submitterEmail,
    String? submitterPhone,
    FormType? formType,
    String? subject,
    String? message,
    String? volunteerInterests,
    String? availableDays,
    String? availableTimes,
    String? skills,
    String? donationAmount,
    String? donationType,
    FormStatus? status,
    String? response,
    DateTime? responseDate,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ContactVolunteerFormModel(
      id: id,
      shelterOwnerId: shelterOwnerId,
      submitterName: submitterName ?? this.submitterName,
      submitterEmail: submitterEmail ?? this.submitterEmail,
      submitterPhone: submitterPhone ?? this.submitterPhone,
      formType: formType ?? this.formType,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      volunteerInterests: volunteerInterests ?? this.volunteerInterests,
      availableDays: availableDays ?? this.availableDays,
      availableTimes: availableTimes ?? this.availableTimes,
      skills: skills ?? this.skills,
      donationAmount: donationAmount ?? this.donationAmount,
      donationType: donationType ?? this.donationType,
      status: status ?? this.status,
      response: response ?? this.response,
      responseDate: responseDate ?? this.responseDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ContactVolunteerFormModel(id: $id, submitterName: $submitterName, formType: $formType, status: $status)';
  }
}
