import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackStatus { pending, reviewed, acknowledged, closed }

extension FeedbackStatusExtension on FeedbackStatus {
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.reviewed:
        return 'Reviewed';
      case FeedbackStatus.acknowledged:
        return 'Acknowledged';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }
}

class FeedbackSubmission {
  final String id;
  final String? name;
  final String? email;
  final String subject;
  final String message;
  final String feedbackType;
  final int rating;
  final DateTime submittedAt;
  final FeedbackStatus status;
  final String? adminResponse;
  final String? respondedBy;
  final DateTime? respondedAt;

  FeedbackSubmission({
    required this.id,
    this.name,
    this.email,
    required this.subject,
    required this.message,
    required this.feedbackType,
    required this.rating,
    required this.submittedAt,
    this.status = FeedbackStatus.pending,
    this.adminResponse,
    this.respondedBy,
    this.respondedAt,
  });

  factory FeedbackSubmission.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FeedbackSubmission(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      feedbackType: data['feedbackType'] ?? 'general',
      rating: data['rating'] ?? 5,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString() == 'FeedbackStatus.${data['status']}',
        orElse: () => FeedbackStatus.pending,
      ),
      adminResponse: data['adminResponse'],
      respondedBy: data['respondedBy'],
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'feedbackType': feedbackType,
      'rating': rating,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.toString().split('.').last,
      'adminResponse': adminResponse,
      'respondedBy': respondedBy,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  FeedbackSubmission copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    String? feedbackType,
    int? rating,
    DateTime? submittedAt,
    FeedbackStatus? status,
    String? adminResponse,
    String? respondedBy,
    DateTime? respondedAt,
  }) {
    return FeedbackSubmission(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      feedbackType: feedbackType ?? this.feedbackType,
      rating: rating ?? this.rating,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedBy: respondedBy ?? this.respondedBy,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.reviewed:
        return 'Reviewed';
      case FeedbackStatus.acknowledged:
        return 'Acknowledged';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }

  String get displayName => statusDisplayName;

  String get feedbackTypeDisplayName {
    switch (feedbackType) {
      case 'suggestion':
        return 'Suggestion';
      case 'bug':
        return 'Bug Report';
      case 'feature':
        return 'Feature Request';
      case 'general':
        return 'General Feedback';
      case 'complaint':
        return 'Complaint';
      default:
        return 'General Feedback';
    }
  }
}
