import 'package:cloud_firestore/cloud_firestore.dart';

enum BlogCategory { training, nutrition, health, grooming, behavior, general }

class BlogPostModel {
  final String id;
  final String title;
  final String content;
  final String excerpt;
  final String authorId;
  final String authorName;
  final BlogCategory category;
  final List<String> tags;
  final String? featuredImageUrl;
  final List<String> imageUrls;
  final int readTime; // in minutes
  final int viewCount;
  final int likeCount;
  final bool isPublished;
  final bool isArchived;
  final bool isScheduled;
  final DateTime publishedAt;
  final DateTime? scheduledPublishAt;
  final DateTime? archivedAt;
  final int flaggedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.authorId,
    required this.authorName,
    required this.category,
    this.tags = const [],
    this.featuredImageUrl,
    this.imageUrls = const [],
    required this.readTime,
    this.viewCount = 0,
    this.likeCount = 0,
    this.isPublished = false,
    this.isArchived = false,
    this.isScheduled = false,
    required this.publishedAt,
    this.scheduledPublishAt,
    this.archivedAt,
    this.flaggedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogPostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BlogPostModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      excerpt: data['excerpt'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      category: BlogCategory.values.firstWhere(
        (e) => e.toString() == 'BlogCategory.${data['category']}',
        orElse: () => BlogCategory.general,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      featuredImageUrl: data['featuredImageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      readTime: data['readTime'] ?? 1,
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      isPublished: data['isPublished'] ?? false,
      isArchived: data['isArchived'] ?? false,
      isScheduled: data['isScheduled'] ?? false,
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] as Timestamp).toDate() 
          : (data['createdAt'] as Timestamp).toDate(),
      scheduledPublishAt: data['scheduledPublishAt'] != null 
          ? (data['scheduledPublishAt'] as Timestamp).toDate() 
          : null,
      archivedAt: data['archivedAt'] != null 
          ? (data['archivedAt'] as Timestamp).toDate() 
          : null,
      flaggedCount: data['flaggedCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'authorId': authorId,
      'authorName': authorName,
      'category': category.toString().split('.').last,
      'tags': tags,
      'featuredImageUrl': featuredImageUrl,
      'imageUrls': imageUrls,
      'readTime': readTime,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'isPublished': isPublished,
      'isArchived': isArchived,
      'isScheduled': isScheduled,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'scheduledPublishAt': scheduledPublishAt != null ? Timestamp.fromDate(scheduledPublishAt!) : null,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'flaggedCount': flaggedCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get categoryName {
    switch (category) {
      case BlogCategory.training:
        return 'Training';
      case BlogCategory.nutrition:
        return 'Nutrition';
      case BlogCategory.health:
        return 'Health';
      case BlogCategory.grooming:
        return 'Grooming';
      case BlogCategory.behavior:
        return 'Behavior';
      case BlogCategory.general:
        return 'General';
    }
  }

  String get formattedPublishDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 30) {
      return '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  BlogPostModel copyWith({
    String? title,
    String? content,
    String? excerpt,
    String? authorId,
    String? authorName,
    BlogCategory? category,
    List<String>? tags,
    String? featuredImageUrl,
    List<String>? imageUrls,
    int? readTime,
    int? viewCount,
    int? likeCount,
    bool? isPublished,
    bool? isArchived,
    bool? isScheduled,
    DateTime? publishedAt,
    DateTime? scheduledPublishAt,
    DateTime? archivedAt,
    int? flaggedCount,
    DateTime? updatedAt,
  }) {
    return BlogPostModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      readTime: readTime ?? this.readTime,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      isScheduled: isScheduled ?? this.isScheduled,
      publishedAt: publishedAt ?? this.publishedAt,
      scheduledPublishAt: scheduledPublishAt ?? this.scheduledPublishAt,
      archivedAt: archivedAt ?? this.archivedAt,
      flaggedCount: flaggedCount ?? this.flaggedCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
