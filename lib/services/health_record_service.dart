import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_record_model.dart';
import 'notification_service.dart';

class HealthRecordService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get health records by pet ID
  Future<List<HealthRecordModel>> getHealthRecordsByPetId(String petId) async {
    try {
      debugPrint(
        'HealthRecordService: Fetching health records for pet: $petId',
      );

      // First try without orderBy to avoid index issues
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('health_records')
            .where('petId', isEqualTo: petId)
            .where('isActive', isEqualTo: true)
            .orderBy('recordDate', descending: true)
            .get();
      } catch (e) {
        debugPrint('OrderBy failed, trying without orderBy: $e');
        querySnapshot = await _firestore
            .collection('health_records')
            .where('petId', isEqualTo: petId)
            .where('isActive', isEqualTo: true)
            .get();
      }

      debugPrint(
        'HealthRecordService: Found ${querySnapshot.docs.length} health records',
      );

      final records = querySnapshot.docs
          .map((doc) {
            try {
              return HealthRecordModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing health record ${doc.id}: $e');
              return null;
            }
          })
          .where((record) => record != null)
          .cast<HealthRecordModel>()
          .toList();

      // Sort manually if orderBy failed
      records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

      debugPrint(
        'HealthRecordService: Parsed ${records.length} health records successfully',
      );

      return records;
    } catch (e) {
      debugPrint('Error getting health records: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  // Test method to fetch all health records (for debugging)
  Future<List<HealthRecordModel>> getAllHealthRecords() async {
    try {
      debugPrint(
        'HealthRecordService: Fetching ALL health records for debugging...',
      );

      final querySnapshot = await _firestore.collection('health_records').get();

      debugPrint(
        'HealthRecordService: Found ${querySnapshot.docs.length} total health records',
      );

      final records = querySnapshot.docs
          .map((doc) {
            try {
              final record = HealthRecordModel.fromFirestore(doc);
              debugPrint(
                'HealthRecordService: Record ${doc.id} - Pet: ${record.petId}, Title: ${record.title}',
              );
              return record;
            } catch (e) {
              debugPrint('Error parsing health record ${doc.id}: $e');
              return null;
            }
          })
          .where((record) => record != null)
          .cast<HealthRecordModel>()
          .toList();

      debugPrint(
        'HealthRecordService: Successfully parsed ${records.length} health records',
      );

      return records;
    } catch (e) {
      debugPrint('Error getting all health records: $e');
      return [];
    }
  }

  // Get health records by veterinarian ID
  Future<List<HealthRecordModel>> getHealthRecordsByVetId(String vetId) async {
    try {
      print(
        '🔍 HealthRecordService: Fetching health records for vet ID: $vetId',
      );

      // First try with orderBy
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('health_records')
            .where('veterinarianId', isEqualTo: vetId)
            .where('isActive', isEqualTo: true)
            .orderBy('recordDate', descending: true)
            .get();
        print('✅ HealthRecordService: Query with orderBy successful');
      } catch (e) {
        print(
          '⚠️ HealthRecordService: OrderBy failed, trying without orderBy: $e',
        );
        querySnapshot = await _firestore
            .collection('health_records')
            .where('veterinarianId', isEqualTo: vetId)
            .where('isActive', isEqualTo: true)
            .get();
        print('✅ HealthRecordService: Query without orderBy successful');
      }

      print(
        '📊 HealthRecordService: Found ${querySnapshot.docs.length} health records for vet',
      );

      if (querySnapshot.docs.isNotEmpty) {
        print('📋 HealthRecordService: Sample health record data:');
        final sampleDoc = querySnapshot.docs.first;
        print('  Document ID: ${sampleDoc.id}');
        print('  Data: ${sampleDoc.data()}');

        // Check if the vetId field matches
        final data = sampleDoc.data() as Map<String, dynamic>;
        print('  veterinarianId in data: ${data['veterinarianId']}');
        print('  Expected vetId: $vetId');
        print('  IDs match: ${data['veterinarianId'] == vetId}');
      } else {
        print(
          '⚠️ HealthRecordService: No records found. Let me check what records exist...',
        );

        // Try to get all records to see what's in the database
        final allRecordsSnapshot = await _firestore
            .collection('health_records')
            .limit(5)
            .get();

        print(
          '📊 HealthRecordService: Found ${allRecordsSnapshot.docs.length} total records in collection',
        );

        if (allRecordsSnapshot.docs.isNotEmpty) {
          print('📋 HealthRecordService: Sample records from collection:');
          for (int i = 0; i < allRecordsSnapshot.docs.length; i++) {
            final doc = allRecordsSnapshot.docs[i];
            final data = doc.data();
            print('  Record ${i + 1}:');
            print('    ID: ${doc.id}');
            print('    veterinarianId: ${data['veterinarianId']}');
            print('    isActive: ${data['isActive']}');
            print('    title: ${data['title']}');
          }
        }
      }

      final records = querySnapshot.docs
          .map((doc) {
            try {
              return HealthRecordModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing health record ${doc.id}: $e');
              return null;
            }
          })
          .where((record) => record != null)
          .cast<HealthRecordModel>()
          .toList();

      print(
        '✅ HealthRecordService: Successfully parsed ${records.length} health records',
      );
      return records;
    } catch (e) {
      print('❌ Error getting vet health records: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ Firebase error code: ${e.code}');
        print('❌ Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  // Add new health record
  Future<String?> addHealthRecord(HealthRecordModel record) async {
    try {
      final docRef = await _firestore
          .collection('health_records')
          .add(record.toFirestore());

      // Get pet name for notifications
      String petName = 'your pet';
      try {
        final petDoc = await _firestore
            .collection('pets')
            .doc(record.petId)
            .get();
        petName = petDoc.exists
            ? (petDoc.data()?['name'] ?? 'your pet')
            : 'your pet';
      } catch (e) {
        print('Warning: Could not get pet name: $e');
      }

      // Send notification about new health record
      try {
        await _notificationService.notifyHealthRecordAdded(
          petName,
          record.type.toString().split('.').last,
        );
      } catch (notificationError) {
        print(
          'Warning: Could not send health record notification: $notificationError',
        );
      }

      // Schedule vaccination reminder if it's a vaccination record
      final recordTypeString = record.type.toString().split('.').last;
      if (recordTypeString.toLowerCase().contains('vaccination') ||
          recordTypeString.toLowerCase().contains('vaccine')) {
        try {
          // Schedule reminder for next vaccination (typically 1 year later)
          final nextVaccinationDate = DateTime(
            record.recordDate.year + 1,
            record.recordDate.month,
            record.recordDate.day,
          );

          await _notificationService.scheduleVaccinationReminder(
            petName,
            recordTypeString,
            nextVaccinationDate,
          );
        } catch (reminderError) {
          print(
            'Warning: Could not schedule vaccination reminder: $reminderError',
          );
        }
      }

      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding health record: $e');
      return null;
    }
  }

  // Update health record
  Future<bool> updateHealthRecord(HealthRecordModel record) async {
    try {
      await _firestore
          .collection('health_records')
          .doc(record.id)
          .update(record.copyWith(updatedAt: DateTime.now()).toFirestore());
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating health record: $e');
      return false;
    }
  }

  // Delete health record (soft delete)
  Future<bool> deleteHealthRecord(String recordId) async {
    try {
      await _firestore.collection('health_records').doc(recordId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting health record: $e');
      return false;
    }
  }

  // Get due health records (vaccinations, medications, etc.)
  Future<List<HealthRecordModel>> getDueHealthRecords(String petId) async {
    try {
      final querySnapshot = await _firestore
          .collection('health_records')
          .where('petId', isEqualTo: petId)
          .where('isActive', isEqualTo: true)
          .get();

      final records = querySnapshot.docs
          .map((doc) => HealthRecordModel.fromFirestore(doc))
          .where((record) => record.isDue)
          .toList();

      records.sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
      return records;
    } catch (e) {
      print('Error getting due health records: $e');
      return [];
    }
  }

  // Get overdue health records
  Future<List<HealthRecordModel>> getOverdueHealthRecords(String petId) async {
    try {
      final querySnapshot = await _firestore
          .collection('health_records')
          .where('petId', isEqualTo: petId)
          .where('isActive', isEqualTo: true)
          .get();

      final records = querySnapshot.docs
          .map((doc) => HealthRecordModel.fromFirestore(doc))
          .where((record) => record.isOverdue)
          .toList();

      records.sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
      return records;
    } catch (e) {
      print('Error getting overdue health records: $e');
      return [];
    }
  }

  // Get health records by type
  Future<List<HealthRecordModel>> getHealthRecordsByType(
    String petId,
    HealthRecordType type,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('health_records')
          .where('petId', isEqualTo: petId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('recordDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => HealthRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting health records by type: $e');
      return [];
    }
  }

  // Search health records
  Future<List<HealthRecordModel>> searchHealthRecords({
    required String petId,
    String? query,
    HealthRecordType? type,
  }) async {
    try {
      Query baseQuery = _firestore.collection('health_records');

      baseQuery = baseQuery.where('petId', isEqualTo: petId);
      baseQuery = baseQuery.where('isActive', isEqualTo: true);

      if (type != null) {
        baseQuery = baseQuery.where(
          'type',
          isEqualTo: type.toString().split('.').last,
        );
      }

      final querySnapshot = await baseQuery.get();

      var records = querySnapshot.docs
          .map((doc) => HealthRecordModel.fromFirestore(doc))
          .toList();

      // Filter by search query if provided
      if (query != null && query.isNotEmpty) {
        final searchText = query.toLowerCase();
        records = records.where((record) {
          return record.title.toLowerCase().contains(searchText) ||
              record.description.toLowerCase().contains(searchText) ||
              (record.medication?.toLowerCase().contains(searchText) ??
                  false) ||
              (record.notes?.toLowerCase().contains(searchText) ?? false);
        }).toList();
      }

      records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      return records;
    } catch (e) {
      print('Error searching health records: $e');
      return [];
    }
  }
}
