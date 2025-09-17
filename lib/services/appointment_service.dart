import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../services/notification_service.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Flag to disable notifications if they're causing issues
  bool _enableNotifications = true;

  void setNotificationsEnabled(bool enabled) {
    _enableNotifications = enabled;
  }

  // Book new appointment
  Future<String?> bookAppointment(AppointmentModel appointment) async {
    try {
      print('Booking appointment with data: ${appointment.toFirestore()}');

      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toFirestore());

      // Update appointment with the generated ID
      final updatedAppointment = appointment.copyWith(id: docRef.id);

      // Schedule reminder notifications
      if (_enableNotifications) {
        try {
          await _scheduleAppointmentReminders(docRef.id, updatedAppointment);
        } catch (reminderError) {
          print('Warning: Could not schedule reminders: $reminderError');
          // Don't fail the appointment booking if reminders fail
        }
      } else {
        print('Notifications disabled, skipping reminder scheduling');
      }

      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error booking appointment: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Get appointments by pet owner ID
  Future<List<AppointmentModel>> getAppointmentsByPetOwner(
    String petOwnerId,
  ) async {
    try {
      print(
        'AppointmentService: Fetching appointments for pet owner: $petOwnerId',
      );

      // Simplified query - no ordering to avoid composite index
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('petOwnerId', isEqualTo: petOwnerId)
          .get();

      print(
        'AppointmentService: Found ${querySnapshot.docs.length} appointments for pet owner',
      );

      final appointments = <AppointmentModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);
          appointments.add(appointment);
          print(
            '  ✓ Parsed appointment: ${doc.id} - ${appointment.reason} - ${appointment.appointmentDate}',
          );
        } catch (parseError) {
          print('  ✗ Error parsing appointment ${doc.id}: $parseError');
          print('  Document data: ${doc.data()}');
        }
      }

      // Sort in memory instead of in query (descending for pet owner)
      appointments.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );

      print(
        'AppointmentService: Successfully parsed ${appointments.length} appointments for pet owner',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting pet owner appointments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get appointments by veterinarian ID
  Future<List<AppointmentModel>> getAppointmentsByVeterinarian(
    String veterinarianId,
  ) async {
    try {
      print(
        'AppointmentService: Fetching appointments for veterinarian: $veterinarianId',
      );

      // Simplified query - no ordering to avoid composite index
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .get();

      print(
        'AppointmentService: Found ${querySnapshot.docs.length} appointments',
      );

      final appointments = <AppointmentModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);
          appointments.add(appointment);
          print(
            '  ✓ Parsed appointment: ${doc.id} - ${appointment.reason} - ${appointment.appointmentDate}',
          );
        } catch (parseError) {
          print('  ✗ Error parsing appointment ${doc.id}: $parseError');
          print('  Document data: ${doc.data()}');
        }
      }

      // Sort in memory instead of in query
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );

      print(
        'AppointmentService: Successfully parsed ${appointments.length} appointments',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting vet appointments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get appointments by pet ID
  Future<List<AppointmentModel>> getAppointmentsByPet(String petId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('petId', isEqualTo: petId)
          .orderBy('appointmentDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pet appointments: $e');
      return [];
    }
  }

  // Search appointments
  Future<List<AppointmentModel>> searchAppointments({
    String? query,
    AppointmentStatus? status,
    AppointmentType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query baseQuery = _firestore.collection('appointments');

      if (status != null) {
        baseQuery = baseQuery.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
      }

      if (type != null) {
        baseQuery = baseQuery.where(
          'type',
          isEqualTo: type.toString().split('.').last,
        );
      }

      final querySnapshot = await baseQuery.get();

      var appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        appointments = appointments.where((appointment) {
          if (startDate != null &&
              appointment.appointmentDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && appointment.appointmentDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Filter by search query if provided
      if (query != null && query.isNotEmpty) {
        final searchText = query.toLowerCase();
        appointments = appointments.where((appointment) {
          return appointment.reason.toLowerCase().contains(searchText) ||
              (appointment.notes?.toLowerCase().contains(searchText) ?? false);
        }).toList();
      }

      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      print('Error searching appointments: $e');
      return [];
    }
  }

  // Get past appointments
  Future<List<AppointmentModel>> getPastAppointments(
    String userId, {
    bool isVet = false,
  }) async {
    try {
      print(
        'AppointmentService: Getting past appointments for user: $userId, isVet: $isVet',
      );

      Query query = _firestore.collection('appointments');

      if (isVet) {
        query = query.where('veterinarianId', isEqualTo: userId);
      } else {
        query = query.where('petOwnerId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();
      final now = DateTime.now();
      final appointments = <AppointmentModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);

          // Filter for past appointments in memory
          if (appointment.appointmentDate.isBefore(now) ||
              appointment.status == AppointmentStatus.completed) {
            appointments.add(appointment);
            print(
              '  ✓ Past appointment: ${doc.id} - ${appointment.reason} - ${appointment.appointmentDate}',
            );
          }
        } catch (parseError) {
          print('  ✗ Error parsing past appointment ${doc.id}: $parseError');
        }
      }

      // Sort by appointment date in memory (most recent first)
      appointments.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );

      print(
        'AppointmentService: Returning ${appointments.length} past appointments',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting past appointments: $e');
      return [];
    }
  }

  // Get cancelled appointments
  Future<List<AppointmentModel>> getCancelledAppointments(
    String userId, {
    bool isVet = false,
  }) async {
    try {
      print(
        'AppointmentService: Getting cancelled appointments for user: $userId, isVet: $isVet',
      );

      Query query = _firestore.collection('appointments');

      if (isVet) {
        query = query.where('veterinarianId', isEqualTo: userId);
      } else {
        query = query.where('petOwnerId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();
      final appointments = <AppointmentModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);

          // Filter for cancelled appointments in memory
          if (appointment.status == AppointmentStatus.cancelled) {
            appointments.add(appointment);
            print(
              '  ✓ Cancelled appointment: ${doc.id} - ${appointment.reason} - ${appointment.appointmentDate}',
            );
          }
        } catch (parseError) {
          print(
            '  ✗ Error parsing cancelled appointment ${doc.id}: $parseError',
          );
        }
      }

      // Sort by appointment date in memory (most recent first)
      appointments.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );

      print(
        'AppointmentService: Returning ${appointments.length} cancelled appointments',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting cancelled appointments: $e');
      return [];
    }
  }

  // Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(
    String userId, {
    bool isVet = false,
  }) async {
    try {
      print(
        'AppointmentService: Getting upcoming appointments for user: $userId, isVet: $isVet',
      );

      // Simplified query - get all appointments for user and filter in memory
      Query query = _firestore.collection('appointments');

      if (isVet) {
        print('AppointmentService: Querying by veterinarianId');
        query = query.where('veterinarianId', isEqualTo: userId);
      } else {
        print('AppointmentService: Querying by petOwnerId');
        query = query.where('petOwnerId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();

      print(
        'AppointmentService: Found ${querySnapshot.docs.length} total appointments',
      );

      final now = DateTime.now();
      final appointments = <AppointmentModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);

          // Filter for upcoming appointments in memory
          if (appointment.appointmentDate.isAfter(now) &&
              appointment.status != AppointmentStatus.cancelled) {
            appointments.add(appointment);
            print(
              '  ✓ Upcoming appointment: ${doc.id} - ${appointment.reason} - ${appointment.appointmentDate}',
            );
          } else if (appointment.status == AppointmentStatus.cancelled) {
            print('  - Skipping cancelled appointment: ${doc.id}');
          }
        } catch (parseError) {
          print(
            '  ✗ Error parsing upcoming appointment ${doc.id}: $parseError',
          );
        }
      }

      // Sort by appointment date in memory
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );

      print(
        'AppointmentService: Returning ${appointments.length} valid upcoming appointments',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting upcoming appointments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get today's appointments for veterinarian
  Future<List<AppointmentModel>> getTodaysAppointments(
    String veterinarianId,
  ) async {
    try {
      print(
        'AppointmentService: Getting today\'s appointments for vet: $veterinarianId',
      );

      // Simplified query - get all appointments for veterinarian and filter in memory
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .get();

      print(
        'AppointmentService: Found ${querySnapshot.docs.length} total appointments',
      );

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final appointments = <AppointmentModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);

          // Filter for today's appointments in memory
          if (appointment.appointmentDate.isAfter(startOfDay) &&
              appointment.appointmentDate.isBefore(endOfDay)) {
            appointments.add(appointment);
            print(
              '  ✓ Today\'s appointment: ${doc.id} - ${appointment.reason} - ${appointment.timeSlot}',
            );
          }
        } catch (parseError) {
          print('  ✗ Error parsing appointment ${doc.id}: $parseError');
        }
      }

      // Sort by appointment date
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );

      print(
        'AppointmentService: Filtered to ${appointments.length} today\'s appointments',
      );
      return appointments;
    } catch (e) {
      print('AppointmentService: Error getting today\'s appointments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Update appointment
  Future<bool> updateAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(
            appointment.copyWith(updatedAt: DateTime.now()).toFirestore(),
          );
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating appointment: $e');
      return false;
    }
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      // Get appointment details before cancelling for notification
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!appointmentDoc.exists) return false;

      final appointment = AppointmentModel.fromFirestore(appointmentDoc);

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Cancel scheduled reminders
      await _cancelAppointmentReminders(appointmentId);

      // Send cancellation notification
      if (_enableNotifications) {
        try {
          // Get pet name for notification
          final petDoc = await _firestore
              .collection('pets')
              .doc(appointment.petId)
              .get();
          final petName = petDoc.exists
              ? (petDoc.data()?['name'] ?? 'your pet')
              : 'your pet';

          await _notificationService.notifyAppointmentCancelled(
            appointment,
            petName,
          );
        } catch (notificationError) {
          print(
            'Warning: Could not send cancellation notification: $notificationError',
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }

  // Confirm appointment
  Future<bool> confirmAppointment(String appointmentId) async {
    try {
      // Get appointment details before confirming for notification
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!appointmentDoc.exists) return false;

      final appointment = AppointmentModel.fromFirestore(appointmentDoc);

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.confirmed.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send confirmation notification
      if (_enableNotifications) {
        try {
          // Get pet name for notification
          final petDoc = await _firestore
              .collection('pets')
              .doc(appointment.petId)
              .get();
          final petName = petDoc.exists
              ? (petDoc.data()?['name'] ?? 'your pet')
              : 'your pet';

          await _notificationService.notifyAppointmentConfirmed(
            appointment,
            petName,
          );
        } catch (notificationError) {
          print(
            'Warning: Could not send confirmation notification: $notificationError',
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error confirming appointment: $e');
      return false;
    }
  }

  // Complete appointment with medical details
  Future<bool> completeAppointment({
    required String appointmentId,
    String? diagnosis,
    String? treatment,
    String? prescription,
    double? cost,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': AppointmentStatus.completed.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (treatment != null) updateData['treatment'] = treatment;
      if (prescription != null) updateData['prescription'] = prescription;
      if (cost != null) updateData['cost'] = cost;
      if (notes != null) updateData['notes'] = notes;

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error completing appointment: $e');
      return false;
    }
  }

  // Get available time slots for a veterinarian on a specific date
  Future<List<String>> getAvailableTimeSlots(
    String veterinarianId,
    DateTime date,
  ) async {
    try {
      print(
        'AppointmentService: Getting available slots for vet: $veterinarianId on date: $date',
      );

      // Simplified query - get all appointments for veterinarian and filter in memory
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .get();

      print(
        'AppointmentService: Found ${querySnapshot.docs.length} total appointments for vet',
      );

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bookedSlots = <String>{};

      for (var doc in querySnapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);

          // Filter for appointments on the selected date in memory
          if (appointment.appointmentDate.isAfter(startOfDay) &&
              appointment.appointmentDate.isBefore(endOfDay) &&
              appointment.status != AppointmentStatus.cancelled) {
            bookedSlots.add(appointment.timeSlot);
            print(
              '  ✓ Booked slot: ${appointment.timeSlot} on ${appointment.appointmentDate}',
            );
          }
        } catch (parseError) {
          print('  ✗ Error parsing appointment ${doc.id}: $parseError');
        }
      }

      // Define available time slots (9 AM to 5 PM)
      final allSlots = [
        '09:00',
        '09:30',
        '10:00',
        '10:30',
        '11:00',
        '11:30',
        '12:00',
        '12:30',
        '13:00',
        '13:30',
        '14:00',
        '14:30',
        '15:00',
        '15:30',
        '16:00',
        '16:30',
        '17:00',
      ];

      final availableSlots = allSlots
          .where((slot) => !bookedSlots.contains(slot))
          .toList();

      print('AppointmentService: Booked slots: ${bookedSlots.toList()}');
      print('AppointmentService: Available slots: $availableSlots');

      return availableSlots;
    } catch (e) {
      print('AppointmentService: Error getting available slots: $e');
      print('AppointmentService: Stack trace: ${StackTrace.current}');

      // Return all slots as available if there's an error
      return [
        '09:00',
        '09:30',
        '10:00',
        '10:30',
        '11:00',
        '11:30',
        '12:00',
        '12:30',
        '13:00',
        '13:30',
        '14:00',
        '14:30',
        '15:00',
        '15:30',
        '16:00',
        '16:30',
        '17:00',
      ];
    }
  }

  // Calendar view - get appointments for specific date range
  Future<Map<DateTime, List<AppointmentModel>>> getAppointmentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isVet = false,
  }) async {
    try {
      Query query = _firestore.collection('appointments');

      if (userId != null) {
        if (isVet) {
          query = query.where('veterinarianId', isEqualTo: userId);
        } else {
          query = query.where('petOwnerId', isEqualTo: userId);
        }
      }

      final querySnapshot = await query
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('appointmentDate')
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Group appointments by date
      final Map<DateTime, List<AppointmentModel>> appointmentsByDate = {};

      for (final appointment in appointments) {
        final dateKey = DateTime(
          appointment.appointmentDate.year,
          appointment.appointmentDate.month,
          appointment.appointmentDate.day,
        );

        appointmentsByDate[dateKey] ??= [];
        appointmentsByDate[dateKey]!.add(appointment);
      }

      return appointmentsByDate;
    } catch (e) {
      print('Error getting appointments by date range: $e');
      return {};
    }
  }

  // Schedule notification reminders
  Future<void> _scheduleAppointmentReminders(
    String appointmentId,
    AppointmentModel appointment,
  ) async {
    try {
      print('Scheduling reminders for appointment: $appointmentId');

      // Validate appointment date
      if (appointment.appointmentDate.isBefore(DateTime.now())) {
        print('Warning: Appointment is in the past, skipping reminders');
        return;
      }

      // Generate safe hash codes for IDs
      final baseHash = appointmentId.hashCode.abs();
      final dayReminderId =
          (baseHash % 1000000) + 1000; // Ensure positive, reasonable range
      final hourReminderId = (baseHash % 1000000) + 2000;

      // Schedule 24-hour reminder
      final dayBefore = appointment.appointmentDate.subtract(
        const Duration(days: 1),
      );
      if (dayBefore.isAfter(DateTime.now())) {
        print('Scheduling 24h reminder with ID: $dayReminderId');
        await _notificationService.scheduleNotification(
          id: dayReminderId,
          title: 'Appointment Reminder',
          body: 'Your appointment is tomorrow at ${appointment.timeSlot}',
          scheduledDate: dayBefore,
        );
      }

      // Schedule 1-hour reminder
      final hourBefore = appointment.appointmentDate.subtract(
        const Duration(hours: 1),
      );
      if (hourBefore.isAfter(DateTime.now())) {
        print('Scheduling 1h reminder with ID: $hourReminderId');
        await _notificationService.scheduleNotification(
          id: hourReminderId,
          title: 'Appointment Starting Soon',
          body: 'Your appointment starts in 1 hour at ${appointment.timeSlot}',
          scheduledDate: hourBefore,
        );
      }

      print('Successfully scheduled reminders');
    } catch (e) {
      print('Error scheduling reminders: $e');
      print('Reminder error stack trace: ${StackTrace.current}');
      rethrow; // Re-throw so the calling function can handle it
    }
  }

  // Cancel appointment reminders
  Future<void> _cancelAppointmentReminders(String appointmentId) async {
    try {
      // Use same ID generation logic as scheduling
      final baseHash = appointmentId.hashCode.abs();
      final dayReminderId = (baseHash % 1000000) + 1000;
      final hourReminderId = (baseHash % 1000000) + 2000;

      await _notificationService.cancelNotification(dayReminderId);
      await _notificationService.cancelNotification(hourReminderId);
    } catch (e) {
      print('Error canceling reminders: $e');
    }
  }

  // Add medical concerns/notes to appointment
  Future<bool> addMedicalConcerns(String appointmentId, String concerns) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': concerns,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding medical concerns: $e');
      return false;
    }
  }

  // Admin Statistics
  Future<Map<String, dynamic>> getBookingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('appointments');

      if (startDate != null && endDate != null) {
        query = query
            .where(
              'appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
      }

      final querySnapshot = await query.get();
      final appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Calculate statistics
      final totalBookings = appointments.length;
      final completedBookings = appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .length;
      final cancelledBookings = appointments
          .where((a) => a.status == AppointmentStatus.cancelled)
          .length;
      final upcomingBookings = appointments.where((a) => a.isUpcoming).length;

      // Group by appointment type
      final Map<String, int> bookingsByType = {};
      for (final appointment in appointments) {
        final type = appointment.type.toString().split('.').last;
        bookingsByType[type] = (bookingsByType[type] ?? 0) + 1;
      }

      // Group by status
      final Map<String, int> bookingsByStatus = {};
      for (final appointment in appointments) {
        final status = appointment.status.toString().split('.').last;
        bookingsByStatus[status] = (bookingsByStatus[status] ?? 0) + 1;
      }

      // Monthly trends (if date range is provided)
      final Map<String, int> monthlyBookings = {};
      if (startDate != null && endDate != null) {
        for (final appointment in appointments) {
          final monthKey =
              '${appointment.appointmentDate.year}-${appointment.appointmentDate.month.toString().padLeft(2, '0')}';
          monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
        }
      }

      // Average revenue (if cost data is available)
      final appointmentsWithCost = appointments
          .where((a) => a.cost != null && a.cost! > 0)
          .toList();
      final totalRevenue = appointmentsWithCost.fold<double>(
        0,
        (sum, a) => sum + (a.cost ?? 0),
      );
      final averageRevenue = appointmentsWithCost.isNotEmpty
          ? totalRevenue / appointmentsWithCost.length
          : 0.0;

      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'upcomingBookings': upcomingBookings,
        'completionRate': totalBookings > 0
            ? (completedBookings / totalBookings * 100).round()
            : 0,
        'cancellationRate': totalBookings > 0
            ? (cancelledBookings / totalBookings * 100).round()
            : 0,
        'bookingsByType': bookingsByType,
        'bookingsByStatus': bookingsByStatus,
        'monthlyBookings': monthlyBookings,
        'totalRevenue': totalRevenue,
        'averageRevenue': averageRevenue,
      };
    } catch (e) {
      print('Error getting booking statistics: $e');
      return {};
    }
  }
}
