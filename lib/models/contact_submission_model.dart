import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactStatus { pending, inProgress, resolved, closed }

extension ContactStatusExtension on ContactStatus {
  String get displayName {
    switch (this) {
      case ContactStatus.pending:
        return 'Pending';
      case ContactStatus.inProgress:
        return 'In Progress';
      case ContactStatus.resolved:
        return 'Resolved';
      case ContactStatus.closed:
        return 'Closed';
    }
  }
}

class ContactSubmission {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final DateTime submittedAt;
  final ContactStatus status;
  final String? adminNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  ContactSubmission({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.status = ContactStatus.pending,
    this.adminNotes,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory ContactSubmission.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ContactSubmission(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      status: ContactStatus.values.firstWhere(
        (e) => e.toString() == 'ContactStatus.${data['status']}',
        orElse: () => ContactStatus.pending,
      ),
      adminNotes: data['adminNotes'],
      resolvedBy: data['resolvedBy'],
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.toString().split('.').last,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  ContactSubmission copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    DateTime? submittedAt,
    ContactStatus? status,
    String? adminNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) {
    return ContactSubmission(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ContactStatus.pending:
        return 'Pending';
      case ContactStatus.inProgress:
        return 'In Progress';
      case ContactStatus.resolved:
        return 'Resolved';
      case ContactStatus.closed:
        return 'Closed';
    }
  }

  String get displayName => statusDisplayName;
}
