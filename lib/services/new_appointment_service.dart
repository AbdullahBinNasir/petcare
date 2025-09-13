import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../models/new_appointment_model.dart';
import 'notification_service.dart';

class NewAppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Cache for appointments
  final Map<String, List<NewAppointmentModel>> _appointmentCache = {};
  Timer? _cacheTimer;

  // Available time slots (9 AM to 5 PM)
  static const List<String> availableTimeSlots = [
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

  NewAppointmentService() {
    _initializeCacheTimer();
  }

  void _initializeCacheTimer() {
    // Clear cache every 5 minutes to ensure fresh data
    _cacheTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _appointmentCache.clear();
    });
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    super.dispose();
  }

  // MARK: - Core Booking Functions

  /// Book a new appointment
  Future<String?> bookAppointment(NewAppointmentModel appointment) async {
    try {
      // Validate appointment
      final validation = _validateAppointment(appointment);
      if (validation != null) {
        throw Exception(validation);
      }

      // Create appointment document
      final docRef = await _firestore.collection('appointments').add({
        ...appointment.toFirestore(),
        'id': '', // Will be set after creation
      });

      // Update with the generated ID
      await docRef.update({'id': docRef.id});

      // Schedule notifications
      await _scheduleAppointmentNotifications(docRef.id, appointment);

      // Clear relevant caches
      _clearRelevantCaches(appointment);

      debugPrint('✅ Appointment booked successfully: ${docRef.id}');
      notifyListeners();

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error booking appointment: $e');
      rethrow;
    }
  }

  /// Get available time slots for a veterinarian on a specific date
  Future<List<String>> getAvailableTimeSlots(
    String veterinarianId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('isActive', isEqualTo: true)
          .get();

      final bookedSlots = querySnapshot.docs
          .map((doc) => NewAppointmentModel.fromFirestore(doc))
          .where(
            (appointment) =>
                appointment.status != AppointmentStatus.cancelled &&
                appointment.status != AppointmentStatus.noShow,
          )
          .map((appointment) => appointment.timeSlot)
          .toSet();

      return availableTimeSlots
          .where((slot) => !bookedSlots.contains(slot))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting available slots: $e');
      return [];
    }
  }

  // MARK: - Calendar & Viewing Functions

  /// Get appointments for a specific date range (for calendar view)
  Future<Map<DateTime, List<NewAppointmentModel>>> getAppointmentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isVeterinarian = false,
  }) async {
    try {
      Query query;

      // Use simpler queries to avoid composite index requirements
      if (userId != null) {
        if (isVeterinarian) {
          query = _firestore
              .collection('appointments')
              .where('veterinarianId', isEqualTo: userId)
              .where(
                'appointmentDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'appointmentDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('appointmentDate');
        } else {
          query = _firestore
              .collection('appointments')
              .where('petOwnerId', isEqualTo: userId)
              .where(
                'appointmentDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'appointmentDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('appointmentDate');
        }
      } else {
        query = _firestore
            .collection('appointments')
            .where(
              'appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('appointmentDate');
      }

      final querySnapshot = await query.get();
      final appointments = querySnapshot.docs
          .map((doc) => NewAppointmentModel.fromFirestore(doc))
          .where(
            (appointment) => appointment.isActive,
          ) // Filter active in memory
          .toList();

      // Group by date
      final Map<DateTime, List<NewAppointmentModel>> groupedAppointments = {};

      for (final appointment in appointments) {
        final dateKey = DateTime(
          appointment.appointmentDate.year,
          appointment.appointmentDate.month,
          appointment.appointmentDate.day,
        );

        groupedAppointments[dateKey] ??= [];
        groupedAppointments[dateKey]!.add(appointment);
      }

      return groupedAppointments;
    } catch (e) {
      debugPrint('❌ Error getting appointments by date range: $e');
      return {};
    }
  }

  /// Get upcoming appointments for a user
  Future<List<NewAppointmentModel>> getUpcomingAppointments({
    String? userId,
    bool isVeterinarian = false,
    int limit = 10,
  }) async {
    try {
      final cacheKey = 'upcoming_${userId}_${isVeterinarian}_$limit';

      // Check cache first
      if (_appointmentCache.containsKey(cacheKey)) {
        return _appointmentCache[cacheKey]!;
      }

      Query query;

      // Use simpler queries to avoid composite index requirements
      if (userId != null) {
        if (isVeterinarian) {
          query = _firestore
              .collection('appointments')
              .where('veterinarianId', isEqualTo: userId)
              .where(
                'appointmentDate',
                isGreaterThan: Timestamp.fromDate(DateTime.now()),
              )
              .orderBy('appointmentDate');
        } else {
          query = _firestore
              .collection('appointments')
              .where('petOwnerId', isEqualTo: userId)
              .where(
                'appointmentDate',
                isGreaterThan: Timestamp.fromDate(DateTime.now()),
              )
              .orderBy('appointmentDate');
        }
      } else {
        query = _firestore
            .collection('appointments')
            .where(
              'appointmentDate',
              isGreaterThan: Timestamp.fromDate(DateTime.now()),
            )
            .orderBy('appointmentDate');
      }

      final querySnapshot = await query.limit(limit).get();

      final appointments = querySnapshot.docs
          .map((doc) => NewAppointmentModel.fromFirestore(doc))
          .where(
            (appointment) => appointment.isUpcoming && appointment.isActive,
          )
          .toList();

      // Cache the results
      _appointmentCache[cacheKey] = appointments;

      return appointments;
    } catch (e) {
      debugPrint('❌ Error getting upcoming appointments: $e');
      return [];
    }
  }

  /// Get today's appointments for a veterinarian
  Future<List<NewAppointmentModel>> getTodaysAppointments(
    String veterinarianId,
  ) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('veterinarianId', isEqualTo: veterinarianId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('isActive', isEqualTo: true)
          .orderBy('appointmentDate')
          .get();

      return querySnapshot.docs
          .map((doc) => NewAppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting today\'s appointments: $e');
      return [];
    }
  }

  // MARK: - Helper Methods

  static String _appointmentStatusToString(AppointmentStatus status) {
    return status.toString().split('.').last;
  }

  static String _appointmentTypeToString(AppointmentType type) {
    return type.toString().split('.').last;
  }

  // MARK: - Appointment Management

  /// Update appointment status
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': _appointmentStatusToString(newStatus),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _appointmentCache.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating appointment status: $e');
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (reason != null) {
        updateData['cancellationReason'] = reason;
      }

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);

      // Cancel notifications
      await _cancelAppointmentNotifications(appointmentId);

      _appointmentCache.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling appointment: $e');
      return false;
    }
  }

  /// Add medical concerns to appointment
  Future<bool> addMedicalConcerns(String appointmentId, String concerns) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'medicalConcerns': concerns,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _appointmentCache.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding medical concerns: $e');
      return false;
    }
  }

  /// Complete appointment with details
  Future<bool> completeAppointment({
    required String appointmentId,
    String? diagnosis,
    String? treatment,
    String? prescription,
    double? cost,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'completed',
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

      _appointmentCache.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error completing appointment: $e');
      return false;
    }
  }

  // MARK: - Admin Statistics

  /// Get booking statistics for admin dashboard
  Future<Map<String, dynamic>> getBookingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('isActive', isEqualTo: true);

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
          .map((doc) => NewAppointmentModel.fromFirestore(doc))
          .toList();

      // Calculate basic statistics
      final totalAppointments = appointments.length;
      final completedAppointments = appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .length;
      final cancelledAppointments = appointments
          .where((a) => a.status == AppointmentStatus.cancelled)
          .length;
      final upcomingAppointments = appointments
          .where((a) => a.isUpcoming)
          .length;
      final noShowAppointments = appointments
          .where((a) => a.status == AppointmentStatus.noShow)
          .length;

      // Calculate rates
      final completionRate = totalAppointments > 0
          ? (completedAppointments / totalAppointments * 100).round()
          : 0;
      final cancellationRate = totalAppointments > 0
          ? (cancelledAppointments / totalAppointments * 100).round()
          : 0;
      final noShowRate = totalAppointments > 0
          ? (noShowAppointments / totalAppointments * 100).round()
          : 0;

      // Group by type
      final Map<String, int> appointmentsByType = {};
      for (final appointment in appointments) {
        final type = appointment.typeDisplayName;
        appointmentsByType[type] = (appointmentsByType[type] ?? 0) + 1;
      }

      // Group by status
      final Map<String, int> appointmentsByStatus = {};
      for (final appointment in appointments) {
        final status = appointment.statusDisplayName;
        appointmentsByStatus[status] = (appointmentsByStatus[status] ?? 0) + 1;
      }

      // Calculate revenue
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

      // Monthly breakdown (if date range provided)
      final Map<String, int> monthlyAppointments = {};
      if (startDate != null && endDate != null) {
        for (final appointment in appointments) {
          final monthKey =
              '${appointment.appointmentDate.year}-${appointment.appointmentDate.month.toString().padLeft(2, '0')}';
          monthlyAppointments[monthKey] =
              (monthlyAppointments[monthKey] ?? 0) + 1;
        }
      }

      return {
        'totalAppointments': totalAppointments,
        'completedAppointments': completedAppointments,
        'cancelledAppointments': cancelledAppointments,
        'upcomingAppointments': upcomingAppointments,
        'noShowAppointments': noShowAppointments,
        'completionRate': completionRate,
        'cancellationRate': cancellationRate,
        'noShowRate': noShowRate,
        'appointmentsByType': appointmentsByType,
        'appointmentsByStatus': appointmentsByStatus,
        'totalRevenue': totalRevenue,
        'averageRevenue': averageRevenue,
        'monthlyAppointments': monthlyAppointments,
      };
    } catch (e) {
      debugPrint('❌ Error getting booking statistics: $e');
      return {};
    }
  }

  // MARK: - Notification Management

  /// Schedule appointment notifications
  Future<void> _scheduleAppointmentNotifications(
    String appointmentId,
    NewAppointmentModel appointment,
  ) async {
    try {
      // Schedule 24-hour reminder
      final dayBefore = appointment.appointmentDate.subtract(
        const Duration(days: 1),
      );
      if (dayBefore.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: _generateNotificationId(appointmentId, '24h'),
          title: 'Appointment Reminder',
          body:
              'Your ${appointment.typeDisplayName.toLowerCase()} appointment is tomorrow at ${appointment.timeSlot}',
          scheduledDate: dayBefore,
        );
      }

      // Schedule 1-hour reminder
      final hourBefore = appointment.appointmentDate.subtract(
        const Duration(hours: 1),
      );
      if (hourBefore.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: _generateNotificationId(appointmentId, '1h'),
          title: 'Appointment Starting Soon',
          body:
              'Your ${appointment.typeDisplayName.toLowerCase()} appointment starts in 1 hour',
          scheduledDate: hourBefore,
        );
      }

      // Update reminder status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'reminderSent': 'scheduled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Notifications scheduled for appointment: $appointmentId');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not schedule notifications: $e');
      // Don't throw error - notifications are not critical
    }
  }

  /// Cancel appointment notifications
  Future<void> _cancelAppointmentNotifications(String appointmentId) async {
    try {
      await _notificationService.cancelNotification(
        _generateNotificationId(appointmentId, '24h'),
      );
      await _notificationService.cancelNotification(
        _generateNotificationId(appointmentId, '1h'),
      );

      debugPrint('✅ Notifications cancelled for appointment: $appointmentId');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not cancel notifications: $e');
    }
  }

  /// Generate safe notification ID
  int _generateNotificationId(String appointmentId, String type) {
    final combined = '$appointmentId-$type';
    final hash = combined.hashCode.abs();
    return (hash % 100000) + 1000; // Keep within reasonable range
  }

  // MARK: - Helper Methods

  /// Validate appointment data
  String? _validateAppointment(NewAppointmentModel appointment) {
    if (appointment.petOwnerId.isEmpty) return 'Pet owner ID is required';
    if (appointment.petId.isEmpty) return 'Pet ID is required';
    if (appointment.veterinarianId.isEmpty)
      return 'Veterinarian ID is required';
    if (appointment.timeSlot.isEmpty) return 'Time slot is required';
    if (appointment.reason.isEmpty) return 'Reason is required';
    if (appointment.appointmentDate.isBefore(DateTime.now()))
      return 'Appointment date cannot be in the past';

    return null;
  }

  /// Clear relevant caches
  void _clearRelevantCaches(NewAppointmentModel appointment) {
    final keysToRemove = <String>[];

    for (final key in _appointmentCache.keys) {
      if (key.contains(appointment.petOwnerId) ||
          key.contains(appointment.veterinarianId) ||
          key.startsWith('upcoming_')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _appointmentCache.remove(key);
    }
  }

  /// Get appointment by ID
  Future<NewAppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (doc.exists) {
        return NewAppointmentModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting appointment by ID: $e');
      return null;
    }
  }

  /// Search appointments
  Future<List<NewAppointmentModel>> searchAppointments({
    String? query,
    AppointmentStatus? status,
    AppointmentType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    bool isVeterinarian = false,
  }) async {
    try {
      debugPrint('🔍 Searching appointments with params:');
      debugPrint('- userId: $userId');
      debugPrint('- isVeterinarian: $isVeterinarian');
      debugPrint('- status: $status');
      debugPrint('- type: $type');

      Query baseQuery = _firestore
          .collection('appointments')
          .where('isActive', isEqualTo: true);

      // Filter by user if specified
      if (userId != null) {
        if (isVeterinarian) {
          baseQuery = baseQuery.where('veterinarianId', isEqualTo: userId);
          debugPrint('🔍 Filtering by veterinarianId: $userId');
        } else {
          baseQuery = baseQuery.where('petOwnerId', isEqualTo: userId);
          debugPrint('🔍 Filtering by petOwnerId: $userId');
        }
      }

      // Filter by status
      if (status != null) {
        baseQuery = baseQuery.where(
          'status',
          isEqualTo: _appointmentStatusToString(status),
        );
      }

      // Filter by type
      if (type != null) {
        baseQuery = baseQuery.where(
          'type',
          isEqualTo: _appointmentTypeToString(type),
        );
      }

      debugPrint('🔍 Executing Firestore query...');
      final querySnapshot = await baseQuery.get();
      debugPrint('🔍 Found ${querySnapshot.docs.length} documents');

      var appointments = <NewAppointmentModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final appointment = NewAppointmentModel.fromFirestore(doc);
          appointments.add(appointment);
          debugPrint(
            '✅ Loaded appointment: ${appointment.id} - ${appointment.reason} - ${appointment.appointmentDate}',
          );
        } catch (e) {
          debugPrint('❌ Error parsing document ${doc.id}: $e');
        }
      }

      // Apply additional filters
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

      // Apply text search
      if (query != null && query.isNotEmpty) {
        final searchText = query.toLowerCase();
        appointments = appointments.where((appointment) {
          return appointment.reason.toLowerCase().contains(searchText) ||
              (appointment.notes?.toLowerCase().contains(searchText) ??
                  false) ||
              (appointment.medicalConcerns?.toLowerCase().contains(
                    searchText,
                  ) ??
                  false);
        }).toList();
      }

      // Sort by appointment date
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );

      return appointments;
    } catch (e) {
      debugPrint('❌ Error searching appointments: $e');
      return [];
    }
  }
}
