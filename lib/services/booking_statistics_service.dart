import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/new_appointment_model.dart';

class BookingStatisticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Statistics data
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  
  // Getters
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;

  // Load comprehensive booking statistics
  Future<void> loadBookingStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all appointments
      QuerySnapshot appointmentsQuery;
      try {
        appointmentsQuery = await _firestore
            .collection('appointments')
            .orderBy('appointmentDate', descending: true)
            .get();
      } catch (e) {
        debugPrint('OrderBy failed, trying without order: $e');
        // Fallback without orderBy in case index is missing
        appointmentsQuery = await _firestore
            .collection('appointments')
            .get();
      }

      final appointments = appointmentsQuery.docs
          .map((doc) => _parseAppointment(doc))
          .where((appointment) => appointment != null)
          .cast<Map<String, dynamic>>()
          .toList();

      debugPrint('Loaded ${appointments.length} appointments');
      debugPrint('Appointments data: $appointments');

      // Calculate statistics
      _statistics = _calculateStatistics(appointments);
      debugPrint('Calculated statistics: $_statistics');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading booking statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Parse appointment document (handles both old and new appointment models)
  Map<String, dynamic>? _parseAppointment(QueryDocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('Parsing appointment data: $data');
      
      // Handle the actual Firestore structure from your database
      return {
        'id': doc.id,
        'petOwnerId': data['petOwnerId'] ?? '',
        'petId': data['petId'] ?? '',
        'veterinarianId': data['veterinarianId'] ?? '',
        'appointmentDate': data['appointmentDate'],
        'timeSlot': data['timeSlot'] ?? '',
        'type': data['type'] ?? 'checkup',
        'status': data['status'] ?? 'scheduled',
        'reason': data['reason'] ?? '',
        'cost': data['cost'] ?? 0.0,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'] ?? data['createdAt'],
        'isActive': data['isActive'] ?? true,
      };
    } catch (e) {
      debugPrint('Error parsing appointment: $e');
      debugPrint('Document data: ${doc.data()}');
      return null;
    }
  }

  // Calculate comprehensive statistics
  Map<String, dynamic> _calculateStatistics(List<Map<String, dynamic>> appointments) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: today.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);
      final thisYear = DateTime(now.year, 1, 1);

    // Time-based statistics
    final todayAppointments = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && _isSameDay(aptDate, today);
    }).toList();

    final weekAppointments = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && aptDate.isAfter(thisWeek.subtract(const Duration(days: 1)));
    }).toList();

    final monthAppointments = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && aptDate.isAfter(thisMonth.subtract(const Duration(days: 1)));
    }).toList();

    final yearAppointments = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && aptDate.isAfter(thisYear.subtract(const Duration(days: 1)));
    }).toList();

    // Status-based statistics
    final statusCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final vetCounts = <String, int>{};
    
    for (final apt in appointments) {
      final status = apt['status']?.toString() ?? 'unknown';
      final type = apt['type']?.toString() ?? 'unknown';
      final vetId = apt['veterinarianId']?.toString() ?? 'unknown';
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      vetCounts[vetId] = (vetCounts[vetId] ?? 0) + 1;
    }

    // Revenue calculation
    double totalRevenue = 0.0;
    double todayRevenue = 0.0;
    double weekRevenue = 0.0;
    double monthRevenue = 0.0;
    double yearRevenue = 0.0;

    for (final apt in appointments) {
      final cost = (apt['cost'] as num?)?.toDouble() ?? 0.0;
      final aptDate = _parseDateTime(apt['appointmentDate']);
      final status = apt['status']?.toString() ?? '';
      
      // Only count completed appointments for revenue
      if (status == 'completed' || status == 'AppointmentStatus.completed') {
        totalRevenue += cost;
        
        if (aptDate != null) {
          if (_isSameDay(aptDate, today)) {
            todayRevenue += cost;
          }
          if (aptDate.isAfter(thisWeek.subtract(const Duration(days: 1)))) {
            weekRevenue += cost;
          }
          if (aptDate.isAfter(thisMonth.subtract(const Duration(days: 1)))) {
            monthRevenue += cost;
          }
          if (aptDate.isAfter(thisYear.subtract(const Duration(days: 1)))) {
            yearRevenue += cost;
          }
        }
      }
    }

    // Average appointment duration (assuming 30 minutes per appointment)
    const averageDurationMinutes = 30;
    final totalAppointmentMinutes = appointments.length * averageDurationMinutes;

    // Peak hours analysis
    final hourlyCounts = <String, int>{};
    for (final apt in appointments) {
      final timeSlot = apt['timeSlot']?.toString() ?? '';
      final hour = _extractHourFromTimeSlot(timeSlot);
      if (hour != null) {
        hourlyCounts[hour.toString()] = (hourlyCounts[hour.toString()] ?? 0) + 1;
      }
    }

    // Find peak hour safely without reduce
    int peakHour = 0;
    if (hourlyCounts.isNotEmpty) {
      int maxCount = 0;
      for (final entry in hourlyCounts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          peakHour = int.tryParse(entry.key) ?? 0;
        }
      }
    }

    return {
      // Volume statistics
      'totalAppointments': appointments.length,
      'todayAppointments': todayAppointments.length,
      'weekAppointments': weekAppointments.length,
      'monthAppointments': monthAppointments.length,
      'yearAppointments': yearAppointments.length,
      
      // Status breakdown
      'statusBreakdown': statusCounts,
      'typeBreakdown': typeCounts,
      'vetBreakdown': vetCounts,
      
      // Revenue statistics
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'weekRevenue': weekRevenue,
      'monthRevenue': monthRevenue,
      'yearRevenue': yearRevenue,
      
      // Performance metrics
      'completionRate': appointments.isNotEmpty 
          ? ((statusCounts['completed'] ?? 0) + (statusCounts['AppointmentStatus.completed'] ?? 0)) / appointments.length * 100
          : 0.0,
      'cancellationRate': appointments.isNotEmpty
          ? ((statusCounts['cancelled'] ?? 0) + (statusCounts['AppointmentStatus.cancelled'] ?? 0)) / appointments.length * 100
          : 0.0,
      'noShowRate': appointments.isNotEmpty
          ? ((statusCounts['noShow'] ?? 0) + (statusCounts['AppointmentStatus.noShow'] ?? 0)) / appointments.length * 100
          : 0.0,
      
      // Time analysis
      'averageAppointmentDuration': averageDurationMinutes,
      'totalAppointmentMinutes': totalAppointmentMinutes,
      'peakHour': peakHour,
      'hourlyDistribution': hourlyCounts,
      
      // Growth metrics
      'growthRate': _calculateGrowthRate(appointments),
      'trends': _calculateTrends(appointments),
    };
    } catch (e) {
      debugPrint('Error calculating statistics: $e');
      // Return empty statistics on error
      return {
        'totalAppointments': 0,
        'todayAppointments': 0,
        'weekAppointments': 0,
        'monthAppointments': 0,
        'yearAppointments': 0,
        'statusBreakdown': <String, int>{},
        'typeBreakdown': <String, int>{},
        'vetBreakdown': <String, int>{},
        'totalRevenue': 0.0,
        'todayRevenue': 0.0,
        'weekRevenue': 0.0,
        'monthRevenue': 0.0,
        'yearRevenue': 0.0,
        'completionRate': 0.0,
        'cancellationRate': 0.0,
        'noShowRate': 0.0,
        'averageAppointmentDuration': 30,
        'totalAppointmentMinutes': 0,
        'peakHour': 0,
        'hourlyDistribution': <String, int>{},
        'growthRate': 0.0,
        'trends': <String, dynamic>{},
      };
    }
  }

  // Helper methods
  DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;
    
    try {
      if (dateData is Timestamp) {
        return dateData.toDate();
      } else if (dateData is DateTime) {
        return dateData;
      } else if (dateData is String) {
        return DateTime.tryParse(dateData);
      } else if (dateData is Map && dateData.containsKey('_seconds')) {
        // Handle Firestore timestamp format
        final seconds = dateData['_seconds'] as int?;
        final nanoseconds = dateData['_nanoseconds'] as int? ?? 0;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e, data: $dateData');
    }
    
    return null;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  int? _extractHourFromTimeSlot(String timeSlot) {
    // Extract hour from time slot (e.g., "09:00 AM" -> 9, "14:30" -> 14)
    final regex = RegExp(r'(\d{1,2}):\d{2}');
    final match = regex.firstMatch(timeSlot);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  double _calculateGrowthRate(List<Map<String, dynamic>> appointments) {
    if (appointments.length < 2) return 0.0;
    
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final thisMonth = DateTime(now.year, now.month, 1);
    
    final lastMonthCount = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && 
             aptDate.isAfter(lastMonth.subtract(const Duration(days: 1))) &&
             aptDate.isBefore(thisMonth);
    }).length;
    
    final thisMonthCount = appointments.where((apt) {
      final aptDate = _parseDateTime(apt['appointmentDate']);
      return aptDate != null && aptDate.isAfter(thisMonth.subtract(const Duration(days: 1)));
    }).length;
    
    if (lastMonthCount == 0) return thisMonthCount > 0 ? 100.0 : 0.0;
    
    return ((thisMonthCount - lastMonthCount) / lastMonthCount) * 100;
  }

  Map<String, dynamic> _calculateTrends(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final trends = <String, dynamic>{};
    
    try {
      // Calculate daily trends for the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayKey = '${date.day}/${date.month}';
        
        final dayAppointments = appointments.where((apt) {
          final aptDate = _parseDateTime(apt['appointmentDate']);
          return aptDate != null && _isSameDay(aptDate, date);
        }).length;
        
        trends[dayKey] = dayAppointments; // Store as int directly instead of List
      }
    } catch (e) {
      debugPrint('Error calculating trends: $e');
    }
    
    return trends;
  }

  // Get specific statistics
  int getTotalAppointments() => _statistics['totalAppointments'] ?? 0;
  int getTodayAppointments() => _statistics['todayAppointments'] ?? 0;
  int getWeekAppointments() => _statistics['weekAppointments'] ?? 0;
  int getMonthAppointments() => _statistics['monthAppointments'] ?? 0;
  double getTotalRevenue() => (_statistics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
  double getCompletionRate() => (_statistics['completionRate'] as num?)?.toDouble() ?? 0.0;
  double getGrowthRate() => (_statistics['growthRate'] as num?)?.toDouble() ?? 0.0;

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Debug method to test data loading
  Future<void> debugLoadData() async {
    try {
      final query = await _firestore.collection('appointments').limit(5).get();
      debugPrint('Debug: Found ${query.docs.length} appointment documents');
      
      for (final doc in query.docs) {
        debugPrint('Debug: Document ID: ${doc.id}');
        debugPrint('Debug: Document data: ${doc.data()}');
        final parsed = _parseAppointment(doc);
        debugPrint('Debug: Parsed appointment: $parsed');
      }
    } catch (e) {
      debugPrint('Debug error: $e');
    }
  }
}
