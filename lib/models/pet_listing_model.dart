import 'package:cloud_firestore/cloud_firestore.dart';

enum PetListingStatus { available, adopted, pending, unavailable }
enum PetListingType { dog, cat, bird, rabbit, hamster, fish, reptile, other }
enum PetListingGender { male, female, unknown }
enum HealthStatus { healthy, sick, recovering, critical, unknown }

class PetListingModel {
  final String id;
  final String shelterOwnerId;
  final String name;
  final PetListingType type;
  final String breed;
  final PetListingGender gender;
  final int age; // in months
  final double? weight;
  final String? color;
  final String? microchipId;
  final List<String> photoUrls;
  final HealthStatus healthStatus;
  final String? medicalNotes;
  final String? description;
  final String? specialNeeds;
  final bool isVaccinated;
  final bool isSpayedNeutered;
  final PetListingStatus status;
  final DateTime? dateArrived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PetListingModel({
    required this.id,
    required this.shelterOwnerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.gender,
    required this.age,
    this.weight,
    this.color,
    this.microchipId,
    this.photoUrls = const [],
    this.healthStatus = HealthStatus.healthy,
    this.medicalNotes,
    this.description,
    this.specialNeeds,
    this.isVaccinated = false,
    this.isSpayedNeutered = false,
    this.status = PetListingStatus.available,
    this.dateArrived,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory PetListingModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return PetListingModel(
        id: doc.id,
        shelterOwnerId: data['shelterOwnerId'] ?? '',
        name: data['name'] ?? '',
        type: _parseType(data['type']),
        breed: data['breed'] ?? '',
        gender: _parseGender(data['gender']),
        age: data['age'] ?? 0,
        weight: data['weight']?.toDouble(),
        color: data['color'],
        microchipId: data['microchipId'],
        photoUrls: _parsePhotoUrls(data['photoUrls']),
        healthStatus: _parseHealthStatus(data['healthStatus']),
        medicalNotes: data['medicalNotes'],
        description: data['description'],
        specialNeeds: data['specialNeeds'],
        isVaccinated: data['isVaccinated'] ?? false,
        isSpayedNeutered: data['isSpayedNeutered'] ?? false,
        status: _parseStatus(data['status']),
        dateArrived: data['dateArrived'] != null 
            ? (data['dateArrived'] as Timestamp).toDate() 
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
      print('Error parsing pet listing from Firestore: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static PetListingType _parseType(dynamic type) {
    if (type == null) return PetListingType.other;
    
    try {
      return PetListingType.values.firstWhere(
        (e) => e.toString() == 'PetListingType.$type',
      );
    } catch (e) {
      print('Error parsing type: $type, defaulting to other');
      return PetListingType.other;
    }
  }

  static PetListingGender _parseGender(dynamic gender) {
    if (gender == null) return PetListingGender.unknown;
    
    try {
      return PetListingGender.values.firstWhere(
        (e) => e.toString() == 'PetListingGender.$gender',
      );
    } catch (e) {
      print('Error parsing gender: $gender, defaulting to unknown');
      return PetListingGender.unknown;
    }
  }

  static HealthStatus _parseHealthStatus(dynamic healthStatus) {
    if (healthStatus == null) return HealthStatus.healthy;
    
    try {
      return HealthStatus.values.firstWhere(
        (e) => e.toString() == 'HealthStatus.$healthStatus',
      );
    } catch (e) {
      print('Error parsing health status: $healthStatus, defaulting to healthy');
      return HealthStatus.healthy;
    }
  }

  static PetListingStatus _parseStatus(dynamic status) {
    if (status == null) return PetListingStatus.available;
    
    try {
      return PetListingStatus.values.firstWhere(
        (e) => e.toString() == 'PetListingStatus.$status',
      );
    } catch (e) {
      print('Error parsing status: $status, defaulting to available');
      return PetListingStatus.available;
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
      'name': name,
      'type': type.toString().split('.').last,
      'breed': breed,
      'gender': gender.toString().split('.').last,
      'age': age,
      'weight': weight,
      'color': color,
      'microchipId': microchipId,
      'photoUrls': photoUrls,
      'healthStatus': healthStatus.toString().split('.').last,
      'medicalNotes': medicalNotes,
      'description': description,
      'specialNeeds': specialNeeds,
      'isVaccinated': isVaccinated,
      'isSpayedNeutered': isSpayedNeutered,
      'status': status.toString().split('.').last,
      'dateArrived': dateArrived != null ? Timestamp.fromDate(dateArrived!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  String get ageString {
    if (age < 12) {
      return '$age month${age == 1 ? '' : 's'}';
    } else {
      final years = (age / 12).floor();
      final remainingMonths = age % 12;
      if (remainingMonths == 0) {
        return '$years year${years == 1 ? '' : 's'}';
      } else {
        return '$years year${years == 1 ? '' : 's'} $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
      }
    }
  }

  String get typeDisplayName {
    switch (type) {
      case PetListingType.dog:
        return 'Dog';
      case PetListingType.cat:
        return 'Cat';
      case PetListingType.bird:
        return 'Bird';
      case PetListingType.rabbit:
        return 'Rabbit';
      case PetListingType.hamster:
        return 'Hamster';
      case PetListingType.fish:
        return 'Fish';
      case PetListingType.reptile:
        return 'Reptile';
      case PetListingType.other:
        return 'Other';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PetListingStatus.available:
        return 'Available';
      case PetListingStatus.adopted:
        return 'Adopted';
      case PetListingStatus.pending:
        return 'Pending';
      case PetListingStatus.unavailable:
        return 'Unavailable';
    }
  }

  PetListingModel copyWith({
    String? name,
    PetListingType? type,
    String? breed,
    PetListingGender? gender,
    int? age,
    double? weight,
    String? color,
    String? microchipId,
    List<String>? photoUrls,
    HealthStatus? healthStatus,
    String? medicalNotes,
    String? description,
    String? specialNeeds,
    bool? isVaccinated,
    bool? isSpayedNeutered,
    PetListingStatus? status,
    DateTime? dateArrived,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PetListingModel(
      id: id,
      shelterOwnerId: shelterOwnerId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      microchipId: microchipId ?? this.microchipId,
      photoUrls: photoUrls ?? this.photoUrls,
      healthStatus: healthStatus ?? this.healthStatus,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      description: description ?? this.description,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isSpayedNeutered: isSpayedNeutered ?? this.isSpayedNeutered,
      status: status ?? this.status,
      dateArrived: dateArrived ?? this.dateArrived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PetListingModel(id: $id, name: $name, type: $type, breed: $breed, status: $status)';
  }
}
