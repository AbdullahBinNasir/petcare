import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/appointment_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> scheduleAppointmentReminder(AppointmentModel appointment) async {
    if (!_isInitialized) await initialize();

    // Schedule reminder 24 hours before
    final reminderTime24h = appointment.appointmentDate.subtract(const Duration(hours: 24));
    if (reminderTime24h.isAfter(DateTime.now())) {
      final baseId = _generateBaseNotificationId(
        appointmentId: appointment.id,
        fallbackKey: '${appointment.petId}-${appointment.veterinarianId}-${appointment.appointmentDate.toIso8601String()}',
      );
      await _scheduleNotification(
        id: baseId + 0,
        title: 'Appointment Reminder',
        body: 'You have an appointment tomorrow at ${appointment.timeSlot}',
        scheduledDate: reminderTime24h,
        payload: 'appointment_${appointment.id}',
      );
    }

    // Schedule reminder 1 hour before
    final reminderTime1h = appointment.appointmentDate.subtract(const Duration(hours: 1));
    if (reminderTime1h.isAfter(DateTime.now())) {
      final baseId = _generateBaseNotificationId(
        appointmentId: appointment.id,
        fallbackKey: '${appointment.petId}-${appointment.veterinarianId}-${appointment.appointmentDate.toIso8601String()}',
      );
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Appointment Starting Soon',
        body: 'Your appointment starts in 1 hour at ${appointment.timeSlot}',
        scheduledDate: reminderTime1h,
        payload: 'appointment_${appointment.id}',
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for upcoming appointments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelAppointmentReminders(String appointmentId) async {
    final baseId = _generateBaseNotificationId(appointmentId: appointmentId);
    await _flutterLocalNotificationsPlugin.cancel(baseId + 0);
    await _flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Generic schedule notification method
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  // Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> requestPermissions() async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}

int _safeHash(String input) {
  return input.hashCode.abs();
}

int _generateBaseNotificationId({required String appointmentId, String? fallbackKey}) {
  // Prefer real appointmentId when available (after Firestore creation)
  if (appointmentId.isNotEmpty) {
    return (_safeHash(appointmentId) % 100000) + 1000;
  }
  // Fallback to a composite key (petId-vetId-date) during pre-ID flows
  final key = (fallbackKey ?? DateTime.now().toIso8601String());
  return (_safeHash(key) % 100000) + 1000;
}
