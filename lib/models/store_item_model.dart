import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreCategory { food, grooming, toys, health, accessories, other }

class StoreItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final StoreCategory category;
  final List<String> imageUrls;
  final String brand;
  final bool isInStock;
  final int stockQuantity;
  final double? rating;
  final int reviewCount;
  final String externalUrl;
  final Map<String, dynamic> specifications;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  StoreItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'USD',
    required this.category,
    this.imageUrls = const [],
    required this.brand,
    this.isInStock = true,
    this.stockQuantity = 0,
    this.rating,
    this.reviewCount = 0,
    required this.externalUrl,
    this.specifications = const {},
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory StoreItemModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return StoreItemModel(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] ?? 0.0).toDouble(),
        currency: data['currency'] ?? 'USD',
        category: StoreCategory.values.firstWhere(
          (e) => e.toString() == 'StoreCategory.${data['category']}',
          orElse: () => StoreCategory.other,
        ),
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        brand: data['brand'] ?? '',
        isInStock: data['isInStock'] ?? true,
        stockQuantity: data['stockQuantity'] ?? 0,
        rating: data['rating']?.toDouble(),
        reviewCount: data['reviewCount'] ?? 0,
        externalUrl: data['externalUrl'] ?? '',
        specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
        tags: List<String>.from(data['tags'] ?? []),
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('Error parsing store item from Firestore: $e');
      print('Document ID: ${doc.id}');
      print('Document data: ${doc.data()}');
      
      // Return a default item to prevent app crash
      return StoreItemModel(
        id: doc.id,
        name: 'Error Loading Item',
        description: 'Failed to load item data',
        price: 0.0,
        category: StoreCategory.other,
        brand: 'Unknown',
        externalUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'category': category.toString().split('.').last,
      'imageUrls': imageUrls,
      'brand': brand,
      'isInStock': isInStock,
      'stockQuantity': stockQuantity,
      'rating': rating ?? 0.0, // Handle null rating
      'reviewCount': reviewCount,
      'externalUrl': externalUrl,
      'specifications': specifications,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get categoryName {
    switch (category) {
      case StoreCategory.food:
        return 'Food';
      case StoreCategory.grooming:
        return 'Grooming';
      case StoreCategory.toys:
        return 'Toys';
      case StoreCategory.health:
        return 'Health';
      case StoreCategory.accessories:
        return 'Accessories';
      case StoreCategory.other:
        return 'Other';
    }
  }

  StoreItemModel copyWith({
    String? name,
    String? description,
    double? price,
    String? currency,
    StoreCategory? category,
    List<String>? imageUrls,
    String? brand,
    bool? isInStock,
    int? stockQuantity,
    double? rating,
    int? reviewCount,
    String? externalUrl,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return StoreItemModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      brand: brand ?? this.brand,
      isInStock: isInStock ?? this.isInStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      externalUrl: externalUrl ?? this.externalUrl,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
