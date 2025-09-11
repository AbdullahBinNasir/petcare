import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
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
      
      final docRef = await _firestore.collection('appointments').add(appointment.toFirestore());
      
      // Schedule reminder notifications
      if (_enableNotifications) {
        try {
          await _scheduleAppointmentReminders(docRef.id, appointment);
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
  Future<List<AppointmentModel>> getAppointmentsByPetOwner(String petOwnerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('petOwnerId', isEqualTo: petOwnerId)
          .orderBy('appointmentDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  // Get appointments by veterinarian ID
  Future<List<AppointmentModel>> getAppointmentsByVeterinarian(String veterinarianId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting vet appointments: $e');
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
        baseQuery = baseQuery.where('status', isEqualTo: status.toString().split('.').last);
      }
      
      if (type != null) {
        baseQuery = baseQuery.where('type', isEqualTo: type.toString().split('.').last);
      }

      final querySnapshot = await baseQuery.get();

      var appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        appointments = appointments.where((appointment) {
          if (startDate != null && appointment.appointmentDate.isBefore(startDate)) {
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

      appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      return appointments;
    } catch (e) {
      print('Error searching appointments: $e');
      return [];
    }
  }

  // Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId, {bool isVet = false}) async {
    try {
      final now = DateTime.now();
      Query query = _firestore.collection('appointments');
      
      if (isVet) {
        query = query.where('veterinarianId', isEqualTo: userId);
      } else {
        query = query.where('petOwnerId', isEqualTo: userId);
      }

      final querySnapshot = await query
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .where((appointment) => appointment.status != AppointmentStatus.cancelled)
          .toList();
    } catch (e) {
      print('Error getting upcoming appointments: $e');
      return [];
    }
  }

  // Get today's appointments for veterinarian
  Future<List<AppointmentModel>> getTodaysAppointments(String veterinarianId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting today\'s appointments: $e');
      return [];
    }
  }

  // Update appointment
  Future<bool> updateAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.copyWith(updatedAt: DateTime.now()).toFirestore());
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
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Cancel scheduled reminders
      await _cancelAppointmentReminders(appointmentId);
      
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
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.confirmed.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
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

      await _firestore.collection('appointments').doc(appointmentId).update(updateData);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error completing appointment: $e');
      return false;
    }
  }

  // Get available time slots for a veterinarian on a specific date
  Future<List<String>> getAvailableTimeSlots(String veterinarianId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final bookedSlots = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .where((appointment) => appointment.status != AppointmentStatus.cancelled)
          .map((appointment) => appointment.timeSlot)
          .toSet();

      // Define available time slots (9 AM to 5 PM)
      final allSlots = [
        '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
        '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
        '15:00', '15:30', '16:00', '16:30', '17:00'
      ];

      return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      print('Error getting available slots: $e');
      return [];
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
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
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
  Future<void> _scheduleAppointmentReminders(String appointmentId, AppointmentModel appointment) async {
    try {
      print('Scheduling reminders for appointment: $appointmentId');
      
      // Validate appointment date
      if (appointment.appointmentDate.isBefore(DateTime.now())) {
        print('Warning: Appointment is in the past, skipping reminders');
        return;
      }
      
      // Generate safe hash codes for IDs
      final baseHash = appointmentId.hashCode.abs();
      final dayReminderId = (baseHash % 1000000) + 1000; // Ensure positive, reasonable range
      final hourReminderId = (baseHash % 1000000) + 2000;
      
      // Schedule 24-hour reminder
      final dayBefore = appointment.appointmentDate.subtract(const Duration(days: 1));
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
      final hourBefore = appointment.appointmentDate.subtract(const Duration(hours: 1));
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
  Future<Map<String, dynamic>> getBookingStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('appointments');
      
      if (startDate != null && endDate != null) {
        query = query
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Calculate statistics
      final totalBookings = appointments.length;
      final completedBookings = appointments.where((a) => a.status == AppointmentStatus.completed).length;
      final cancelledBookings = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;
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
          final monthKey = '${appointment.appointmentDate.year}-${appointment.appointmentDate.month.toString().padLeft(2, '0')}';
          monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
        }
      }
      
      // Average revenue (if cost data is available)
      final appointmentsWithCost = appointments.where((a) => a.cost != null && a.cost! > 0).toList();
      final totalRevenue = appointmentsWithCost.fold<double>(0, (sum, a) => sum + (a.cost ?? 0));
      final averageRevenue = appointmentsWithCost.isNotEmpty ? totalRevenue / appointmentsWithCost.length : 0.0;
      
      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'upcomingBookings': upcomingBookings,
        'completionRate': totalBookings > 0 ? (completedBookings / totalBookings * 100).round() : 0,
        'cancellationRate': totalBookings > 0 ? (cancelledBookings / totalBookings * 100).round() : 0,
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
