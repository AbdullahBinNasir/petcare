import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppointmentDebug {
  // Test appointment model creation and conversion
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

  // Debug appointment fetching for current user
  static Future<void> debugAppointmentFetching(BuildContext context) async {
    try {
      debugPrint('=== Debugging Appointment Fetching ===');
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      
      // Check current user
      final currentUser = authService.currentUserModel;
      debugPrint('Current User: ${currentUser?.fullName} (${currentUser?.email})');
      debugPrint('User Role: ${currentUser?.role}');
      debugPrint('User ID: ${currentUser?.id}');
      debugPrint('Firebase Auth UID: ${authService.currentUser?.uid}');
      if (currentUser != null) {
        debugPrint('User Firestore Data: ${currentUser.toFirestore()}');
      }
      
      if (currentUser == null) {
        debugPrint('✗ No current user found!');
        return;
      }
      
      // Test different appointment fetching methods based on user role
      if (currentUser.role == UserRole.veterinarian) {
        debugPrint('\n--- Testing Veterinarian Appointment Fetching ---');
        
        final firebaseUid = authService.currentUser!.uid;
        
        // Test getting appointments by veterinarian ID
        debugPrint('Fetching appointments for veterinarian Firebase UID: $firebaseUid');
        debugPrint('(User model ID: ${currentUser.id})');
        final vetAppointments = await appointmentService.getAppointmentsByVeterinarian(firebaseUid);
        debugPrint('Veterinarian appointments count: ${vetAppointments.length}');
        
        for (int i = 0; i < vetAppointments.length && i < 5; i++) {
          final apt = vetAppointments[i];
          debugPrint('  Appointment $i: ${apt.id} - ${apt.reason} - ${apt.appointmentDate} - Status: ${apt.status}');
        }
        
        // Test today's appointments
        debugPrint('\nFetching today\'s appointments...');
        final todaysAppointments = await appointmentService.getTodaysAppointments(firebaseUid);
        debugPrint('Today\'s appointments count: ${todaysAppointments.length}');
        
        // Test upcoming appointments
        debugPrint('\nFetching upcoming appointments...');
        final upcomingAppointments = await appointmentService.getUpcomingAppointments(firebaseUid, isVet: true);
        debugPrint('Upcoming appointments count: ${upcomingAppointments.length}');
        
      } else if (currentUser.role == UserRole.petOwner) {
        debugPrint('\n--- Testing Pet Owner Appointment Fetching ---');
        
        final firebaseUid = authService.currentUser!.uid;
        
        // Test getting appointments by pet owner ID
        debugPrint('Fetching appointments for pet owner Firebase UID: $firebaseUid');
        debugPrint('(User model ID: ${currentUser.id})');
        final ownerAppointments = await appointmentService.getAppointmentsByPetOwner(firebaseUid);
        debugPrint('Pet owner appointments count: ${ownerAppointments.length}');
        
        for (int i = 0; i < ownerAppointments.length && i < 5; i++) {
          final apt = ownerAppointments[i];
          debugPrint('  Appointment $i: ${apt.id} - ${apt.reason} - ${apt.appointmentDate} - Status: ${apt.status}');
        }
      }
      
      debugPrint('\n=== Appointment Fetching Debug Completed ===');
    } catch (e) {
      debugPrint('Error in appointment fetching debug: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Debug Firestore connection and data structure
  static Future<void> debugFirestoreData() async {
    try {
      debugPrint('=== Debugging Firestore Data ===');
      
      final firestore = FirebaseFirestore.instance;
      
      // Check appointments collection
      debugPrint('Checking appointments collection...');
      final appointmentsSnapshot = await firestore.collection('appointments').limit(5).get();
      debugPrint('Total appointments found: ${appointmentsSnapshot.docs.length}');
      
      for (var doc in appointmentsSnapshot.docs) {
        debugPrint('Document ID: ${doc.id}');
        debugPrint('Document Data: ${doc.data()}');
        
        // Try to parse the document
        try {
          final appointment = AppointmentModel.fromFirestore(doc);
          debugPrint('✓ Successfully parsed appointment: ${appointment.reason}');
        } catch (e) {
          debugPrint('✗ Error parsing appointment: $e');
        }
      }
      
      // Check users collection
      debugPrint('\nChecking users collection...');
      final usersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'veterinarian').limit(3).get();
      debugPrint('Total veterinarians found: ${usersSnapshot.docs.length}');
      
      for (var doc in usersSnapshot.docs) {
        debugPrint('Veterinarian ID: ${doc.id}');
        debugPrint('Veterinarian Data: ${doc.data()}');
      }
      
      debugPrint('\n=== Firestore Data Debug Completed ===');
    } catch (e) {
      debugPrint('Error in Firestore debug: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Create test appointments for debugging
  static Future<void> createTestAppointments(BuildContext context) async {
    try {
      debugPrint('=== Creating Test Appointments ===');
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      
      final currentUser = authService.currentUserModel;
      if (currentUser == null) {
        debugPrint('✗ No current user found!');
        return;
      }
      
      // Create test appointments for veterinarian
      if (currentUser.role == UserRole.veterinarian) {
        final firebaseUid = authService.currentUser!.uid;
        debugPrint('Creating test appointments for veterinarian Firebase UID: $firebaseUid');
        debugPrint('(User model ID: ${currentUser.id})');
        
        for (int i = 0; i < 3; i++) {
          final testAppointment = AppointmentModel(
            id: '', // Will be auto-generated
            petOwnerId: 'test_owner_$i',
            petId: 'test_pet_$i',
            veterinarianId: firebaseUid, // Use Firebase UID
            appointmentDate: DateTime.now().add(Duration(days: i + 1)),
            timeSlot: '${10 + i}:00',
            type: AppointmentType.values[i % AppointmentType.values.length],
            status: AppointmentStatus.scheduled,
            reason: 'Test appointment $i for debugging',
            notes: 'This is a test appointment created for debugging purposes',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final appointmentId = await appointmentService.bookAppointment(testAppointment);
          if (appointmentId != null) {
            debugPrint('✓ Created test appointment: $appointmentId');
          } else {
            debugPrint('✗ Failed to create test appointment $i');
          }
        }
      }
      
      debugPrint('=== Test Appointment Creation Completed ===');
    } catch (e) {
      debugPrint('Error creating test appointments: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}

// Debug Screen Widget for easy access
class AppointmentDebugScreen extends StatelessWidget {
  const AppointmentDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Debug'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.blue),
                title: const Text('Test Appointment Model'),
                subtitle: const Text('Test appointment creation and conversion'),
                onTap: () {
                  AppointmentDebug.testAppointmentModel();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Check console for results')),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.search, color: Colors.green),
                title: const Text('Debug Appointment Fetching'),
                subtitle: const Text('Check appointment data retrieval for current user'),
                onTap: () async {
                  await AppointmentDebug.debugAppointmentFetching(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Check console for results')),
                    );
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage, color: Colors.purple),
                title: const Text('Debug Firestore Data'),
                subtitle: const Text('Check Firestore connection and data structure'),
                onTap: () async {
                  await AppointmentDebug.debugFirestoreData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Check console for results')),
                    );
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.red),
                title: const Text('Create Test Appointments'),
                subtitle: const Text('Create sample appointments for testing'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Create Test Data?'),
                      content: const Text('This will create sample appointments in your database.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    await AppointmentDebug.createTestAppointments(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test appointments created! Check console for results')),
                      );
                    }
                  }
                },
              ),
            ),
            const Spacer(),
            Card(
              color: Colors.yellow.shade100,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Debug Information:\n'
                  '• Check the console/logs for detailed output\n'
                  '• Test appointments will be created in your Firestore\n'
                  '• This screen is for debugging purposes only',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
