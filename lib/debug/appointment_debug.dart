import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

class AppointmentDebug {
  static void testAppointmentModel() {
    try {
      debugPrint('=== Testing AppointmentModel ===');
      
      // Test enum conversions
      AppointmentModel.testEnumConversion();
      
      // Test creating appointment with various types
      for (AppointmentType type in AppointmentType.values) {
        try {
          final appointment = AppointmentModel(
            id: 'test-${type.toString()}',
            petOwnerId: 'owner1',
            petId: 'pet1',
            veterinarianId: 'vet1',
            appointmentDate: DateTime.now().add(const Duration(days: 1)),
            timeSlot: '10:00',
            type: type,
            reason: 'Test appointment',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final firestoreData = appointment.toFirestore();
          debugPrint('✓ Successfully created appointment with type: $type');
          debugPrint('  Firestore data: $firestoreData');
        } catch (e) {
          debugPrint('✗ Error with type $type: $e');
        }
      }
      
      // Test with all status values
      for (AppointmentStatus status in AppointmentStatus.values) {
        try {
          final appointment = AppointmentModel(
            id: 'test-${status.toString()}',
            petOwnerId: 'owner1',
            petId: 'pet1',
            veterinarianId: 'vet1',
            appointmentDate: DateTime.now().add(const Duration(days: 1)),
            timeSlot: '11:00',
            type: AppointmentType.checkup,
            status: status,
            reason: 'Test appointment',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final firestoreData = appointment.toFirestore();
          debugPrint('✓ Successfully created appointment with status: $status');
        } catch (e) {
          debugPrint('✗ Error with status $status: $e');
        }
      }
      
      debugPrint('=== AppointmentModel tests completed ===');
    } catch (e) {
      debugPrint('Fatal error in appointment testing: $e');
    }
  }
}
