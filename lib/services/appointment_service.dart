import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Book new appointment
  Future<String?> bookAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore.collection('appointments').add(appointment.toFirestore());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error booking appointment: $e');
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
}
