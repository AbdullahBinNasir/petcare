import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessStoryModel {
  final String id;
  final String shelterOwnerId;
  final String petName;
  final String petType;
  final String adopterName;
  final String adopterEmail;
  final String storyTitle;
  final String storyDescription;
  final List<String> photoUrls;
  final DateTime adoptionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isFeatured;

  SuccessStoryModel({
    required this.id,
    required this.shelterOwnerId,
    required this.petName,
    required this.petType,
    required this.adopterName,
    required this.adopterEmail,
    required this.storyTitle,
    required this.storyDescription,
    this.photoUrls = const [],
    required this.adoptionDate,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isFeatured = false,
  });

  factory SuccessStoryModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return SuccessStoryModel(
        id: doc.id,
        shelterOwnerId: data['shelterOwnerId'] ?? '',
        petName: data['petName'] ?? '',
        petType: data['petType'] ?? '',
        adopterName: data['adopterName'] ?? '',
        adopterEmail: data['adopterEmail'] ?? '',
        storyTitle: data['storyTitle'] ?? '',
        storyDescription: data['storyDescription'] ?? '',
        photoUrls: _parsePhotoUrls(data['photoUrls']),
        adoptionDate: data['adoptionDate'] != null 
            ? (data['adoptionDate'] as Timestamp).toDate() 
            : DateTime.now(),
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
        isFeatured: data['isFeatured'] ?? false,
      );
    } catch (e) {
      print('Error parsing success story from Firestore: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static List<String> _parsePhotoUrls(dynamic photoUrls) {
    if (photoUrls == null) return [];
    
    try {
      if (photoUrls is List) {
        return photoUrls.map((url) => url.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing photo URLs: $photoUrls');
      return [];
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shelterOwnerId': shelterOwnerId,
      'petName': petName,
      'petType': petType,
      'adopterName': adopterName,
      'adopterEmail': adopterEmail,
      'storyTitle': storyTitle,
      'storyDescription': storyDescription,
      'photoUrls': photoUrls,
      'adoptionDate': Timestamp.fromDate(adoptionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
  }

  String get timeSinceAdoption {
    final now = DateTime.now();
    final difference = now.difference(adoptionDate);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  SuccessStoryModel copyWith({
    String? petName,
    String? petType,
    String? adopterName,
    String? adopterEmail,
    String? storyTitle,
    String? storyDescription,
    List<String>? photoUrls,
    DateTime? adoptionDate,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFeatured,
  }) {
    return SuccessStoryModel(
      id: id,
      shelterOwnerId: shelterOwnerId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      adopterName: adopterName ?? this.adopterName,
      adopterEmail: adopterEmail ?? this.adopterEmail,
      storyTitle: storyTitle ?? this.storyTitle,
      storyDescription: storyDescription ?? this.storyDescription,
      photoUrls: photoUrls ?? this.photoUrls,
      adoptionDate: adoptionDate ?? this.adoptionDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  String toString() {
    return 'SuccessStoryModel(id: $id, petName: $petName, adopterName: $adopterName, storyTitle: $storyTitle)';
  }
}
