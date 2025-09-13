import 'package:cloud_firestore/cloud_firestore.dart';

enum PetSpecies { dog, cat, bird, rabbit, hamster, fish, reptile, other }
enum PetGender { male, female, unknown }
enum HealthStatus { healthy, sick, recovering, critical, unknown }

class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final PetSpecies species;
  final String breed;
  final PetGender gender;
  final DateTime? dateOfBirth;
  final double? weight;
  final String? color;
  final String? microchipId;
  final List<String> photoUrls;
  final HealthStatus healthStatus;
  final String? medicalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    this.dateOfBirth,
    this.weight,
    this.color,
    this.microchipId,
    this.photoUrls = const [],
    this.healthStatus = HealthStatus.healthy,
    this.medicalNotes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Debug print to see the data structure
      print('Pet data from Firestore: $data');
      
      return PetModel(
        id: doc.id,
        ownerId: data['ownerId'] ?? '',
        name: data['name'] ?? '',
        species: _parseSpecies(data['species']),
        breed: data['breed'] ?? '',
        gender: _parseGender(data['gender']),
        dateOfBirth: data['dateOfBirth'] != null 
            ? (data['dateOfBirth'] as Timestamp).toDate() 
            : null,
        weight: data['weight']?.toDouble(),
        color: data['color'],
        microchipId: data['microchipId'],
        photoUrls: _parsePhotoUrls(data['photoUrls']),
        healthStatus: _parseHealthStatus(data['healthStatus']),
        medicalNotes: data['medicalNotes'],
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('Error parsing pet from Firestore: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static PetSpecies _parseSpecies(dynamic species) {
    if (species == null) return PetSpecies.other;
    
    try {
      return PetSpecies.values.firstWhere(
        (e) => e.toString() == 'PetSpecies.$species',
      );
    } catch (e) {
      print('Error parsing species: $species, defaulting to other');
      return PetSpecies.other;
    }
  }

  static PetGender _parseGender(dynamic gender) {
    if (gender == null) return PetGender.unknown;
    
    try {
      return PetGender.values.firstWhere(
        (e) => e.toString() == 'PetGender.$gender',
      );
    } catch (e) {
      print('Error parsing gender: $gender, defaulting to unknown');
      return PetGender.unknown;
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
      'ownerId': ownerId,
      'name': name,
      'species': species.toString().split('.').last,
      'breed': breed,
      'gender': gender.toString().split('.').last,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'weight': weight,
      'color': color,
      'microchipId': microchipId,
      'photoUrls': photoUrls,
      'healthStatus': healthStatus.toString().split('.').last,
      'medicalNotes': medicalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  int? get ageInMonths {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth!);
    return (difference.inDays / 30).round();
  }

  String get ageString {
    final months = ageInMonths;
    if (months == null) return 'Unknown';
    
    if (months < 12) {
      return '$months month${months == 1 ? '' : 's'}';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year${years == 1 ? '' : 's'}';
      } else {
        return '$years year${years == 1 ? '' : 's'} $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
      }
    }
  }

  PetModel copyWith({
    String? name,
    PetSpecies? species,
    String? breed,
    PetGender? gender,
    DateTime? dateOfBirth,
    double? weight,
    String? color,
    String? microchipId,
    List<String>? photoUrls,
    HealthStatus? healthStatus,
    String? medicalNotes,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PetModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      microchipId: microchipId ?? this.microchipId,
      photoUrls: photoUrls ?? this.photoUrls,
      healthStatus: healthStatus ?? this.healthStatus,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PetModel(id: $id, name: $name, species: $species, breed: $breed, ownerId: $ownerId)';
  }
}