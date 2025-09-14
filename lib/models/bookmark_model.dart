import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookmarkModel {
  final String id;
  final String userId;
  final String postId;
  final String postTitle;
  final String postExcerpt;
  final String? postImageUrl;
  final String postCategory;
  final List<String> postTags;
  final int postReadTime;
  final DateTime bookmarkedAt;
  final DateTime? lastReadAt;
  final bool isRead;
  final String? notes; // User's personal notes about the article
  final int readProgress; // 0-100 percentage

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.postTitle,
    required this.postExcerpt,
    this.postImageUrl,
    required this.postCategory,
    this.postTags = const [],
    required this.postReadTime,
    required this.bookmarkedAt,
    this.lastReadAt,
    this.isRead = false,
    this.notes,
    this.readProgress = 0,
  });

  factory BookmarkModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookmarkModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      postTitle: data['postTitle'] ?? '',
      postExcerpt: data['postExcerpt'] ?? '',
      postImageUrl: data['postImageUrl'],
      postCategory: data['postCategory'] ?? '',
      postTags: List<String>.from(data['postTags'] ?? []),
      postReadTime: data['postReadTime'] ?? 1,
      bookmarkedAt: (data['bookmarkedAt'] as Timestamp).toDate(),
      lastReadAt: data['lastReadAt'] != null 
          ? (data['lastReadAt'] as Timestamp).toDate() 
          : null,
      isRead: data['isRead'] ?? false,
      notes: data['notes'],
      readProgress: data['readProgress'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'postId': postId,
      'postTitle': postTitle,
      'postExcerpt': postExcerpt,
      'postImageUrl': postImageUrl,
      'postCategory': postCategory,
      'postTags': postTags,
      'postReadTime': postReadTime,
      'bookmarkedAt': Timestamp.fromDate(bookmarkedAt),
      'lastReadAt': lastReadAt != null ? Timestamp.fromDate(lastReadAt!) : null,
      'isRead': isRead,
      'notes': notes,
      'readProgress': readProgress,
    };
  }

  BookmarkModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? postTitle,
    String? postExcerpt,
    String? postImageUrl,
    String? postCategory,
    List<String>? postTags,
    int? postReadTime,
    DateTime? bookmarkedAt,
    DateTime? lastReadAt,
    bool? isRead,
    String? notes,
    int? readProgress,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postExcerpt: postExcerpt ?? this.postExcerpt,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      postCategory: postCategory ?? this.postCategory,
      postTags: postTags ?? this.postTags,
      postReadTime: postReadTime ?? this.postReadTime,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isRead: isRead ?? this.isRead,
      notes: notes ?? this.notes,
      readProgress: readProgress ?? this.readProgress,
    );
  }

  String get formattedBookmarkDate {
    final now = DateTime.now();
    final difference = now.difference(bookmarkedAt);

    if (difference.inDays > 30) {
      return '${bookmarkedAt.day}/${bookmarkedAt.month}/${bookmarkedAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedLastReadDate {
    if (lastReadAt == null) return 'Never read';
    
    final now = DateTime.now();
    final difference = now.difference(lastReadAt!);

    if (difference.inDays > 30) {
      return '${lastReadAt!.day}/${lastReadAt!.month}/${lastReadAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get readStatus {
    if (isRead) return 'Read';
    if (readProgress > 0) return 'In Progress';
    return 'Unread';
  }

  Color get readStatusColor {
    if (isRead) return Colors.green;
    if (readProgress > 0) return Colors.orange;
    return Colors.grey;
  }
}
