import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';

enum NotificationType {
  appointment,
  healthRecord,
  vaccination,
  adoption,
  general,
  emergency,
  reminder,
  update,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.toString(),
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => NotificationType.general,
        ),
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        data: json['data'],
      );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  List<NotificationData> _notifications = [];
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Load user preferences
    await _loadPreferences();

    // Initialize local notifications
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

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();

    // Load stored notifications
    await _loadStoredNotifications();

    _isInitialized = true;
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission for notifications');
    } else {
      print('User declined or has not accepted permission for notifications');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  Future<void> _loadStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('stored_notifications') ?? [];
    _notifications = notificationsJson
        .map(
          (json) => NotificationData.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> _saveStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((n) => jsonEncode(n.toJson()))
        .toList();
    await prefs.setStringList('stored_notifications', notificationsJson);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    debugPrint('Notification tapped: ${notificationResponse.payload}');

    // Mark notification as read if it exists
    if (notificationResponse.payload != null) {
      final notificationId = notificationResponse.payload!;
      _markNotificationAsRead(notificationId);
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling a background message: ${message.messageId}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await showInstantNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data['notificationId'],
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');

    // Handle navigation based on notification data
    if (message.data['type'] != null) {
      // Navigate to appropriate screen based on notification type
      // This will be handled by the UI layer
    }
  }

  // Getters
  List<NotificationData> get notifications => List.unmodifiable(_notifications);
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Settings management
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  // Notification management
  Future<void> addNotification(NotificationData notification) async {
    _notifications.insert(0, notification);
    await _saveStoredNotifications();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    _markNotificationAsRead(notificationId);
    await _saveStoredNotifications();
    notifyListeners();
  }

  void _markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationData(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        createdAt: _notifications[index].createdAt,
        isRead: true,
        data: _notifications[index].data,
      );
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map(
          (n) => NotificationData(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
            data: n.data,
          ),
        )
        .toList();
    await _saveStoredNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveStoredNotifications();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveStoredNotifications();
    notifyListeners();
  }

  Future<void> clearOldNotifications({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    _notifications.removeWhere((n) => n.createdAt.isBefore(cutoffDate));
    await _saveStoredNotifications();
    notifyListeners();
  }

  // Appointment Notifications
  Future<void> scheduleAppointmentReminder(AppointmentModel appointment) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    // Schedule reminder 24 hours before
    final reminderTime24h = appointment.appointmentDate.subtract(
      const Duration(hours: 24),
    );
    if (reminderTime24h.isAfter(DateTime.now())) {
      final baseId = _generateBaseNotificationId(
        appointmentId: appointment.id,
        fallbackKey:
            '${appointment.petId}-${appointment.veterinarianId}-${appointment.appointmentDate.toIso8601String()}',
      );
      await _scheduleNotification(
        id: baseId + 0,
        title: 'Appointment Reminder',
        body: 'You have an appointment tomorrow at ${appointment.timeSlot}',
        scheduledDate: reminderTime24h,
        payload: 'appointment_${appointment.id}',
        type: NotificationType.appointment,
      );
    }

    // Schedule reminder 1 hour before
    final reminderTime1h = appointment.appointmentDate.subtract(
      const Duration(hours: 1),
    );
    if (reminderTime1h.isAfter(DateTime.now())) {
      final baseId = _generateBaseNotificationId(
        appointmentId: appointment.id,
        fallbackKey:
            '${appointment.petId}-${appointment.veterinarianId}-${appointment.appointmentDate.toIso8601String()}',
      );
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Appointment Starting Soon',
        body: 'Your appointment starts in 1 hour at ${appointment.timeSlot}',
        scheduledDate: reminderTime1h,
        payload: 'appointment_${appointment.id}',
        type: NotificationType.appointment,
      );
    }
  }

  Future<void> notifyAppointmentBooked(
    AppointmentModel appointment,
    String petName,
  ) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'appointment_booked_${appointment.id}',
      title: 'Appointment Booked Successfully',
      body:
          'Your appointment for $petName is scheduled for ${_formatDate(appointment.appointmentDate)} at ${appointment.timeSlot}',
      type: NotificationType.appointment,
      createdAt: DateTime.now(),
      data: {
        'appointmentId': appointment.id,
        'petId': appointment.petId,
        'veterinarianId': appointment.veterinarianId,
      },
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  Future<void> notifyAppointmentCancelled(
    AppointmentModel appointment,
    String petName,
  ) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'appointment_cancelled_${appointment.id}',
      title: 'Appointment Cancelled',
      body:
          'Your appointment for $petName on ${_formatDate(appointment.appointmentDate)} has been cancelled',
      type: NotificationType.appointment,
      createdAt: DateTime.now(),
      data: {
        'appointmentId': appointment.id,
        'petId': appointment.petId,
        'veterinarianId': appointment.veterinarianId,
      },
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  Future<void> notifyAppointmentConfirmed(
    AppointmentModel appointment,
    String petName,
  ) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'appointment_confirmed_${appointment.id}',
      title: 'Appointment Confirmed',
      body:
          'Your appointment for $petName on ${_formatDate(appointment.appointmentDate)} has been confirmed by the veterinarian',
      type: NotificationType.appointment,
      createdAt: DateTime.now(),
      data: {
        'appointmentId': appointment.id,
        'petId': appointment.petId,
        'veterinarianId': appointment.veterinarianId,
      },
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  // Health Record Notifications
  Future<void> notifyHealthRecordAdded(
    String petName,
    String recordType,
  ) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'health_record_added_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Health Record Added',
      body: 'A new $recordType record has been added for $petName',
      type: NotificationType.healthRecord,
      createdAt: DateTime.now(),
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  // Vaccination Reminders
  Future<void> scheduleVaccinationReminder(
    String petName,
    String vaccineName,
    DateTime dueDate,
  ) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    final reminderTime = dueDate.subtract(
      const Duration(days: 7),
    ); // 7 days before
    if (reminderTime.isAfter(DateTime.now())) {
      final notificationId =
          'vaccination_reminder_${petName}_${vaccineName}_${dueDate.millisecondsSinceEpoch}';

      await _scheduleNotification(
        id: _safeHash(notificationId),
        title: 'Vaccination Due Soon',
        body:
            '$petName\'s $vaccineName vaccination is due on ${_formatDate(dueDate)}',
        scheduledDate: reminderTime,
        payload: notificationId,
        type: NotificationType.vaccination,
      );
    }
  }

  // Adoption Notifications
  Future<void> notifyAdoptionRequestReceived(
    String petName,
    String adopterName,
  ) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'adoption_request_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Adoption Request',
      body: '$adopterName has requested to adopt $petName',
      type: NotificationType.adoption,
      createdAt: DateTime.now(),
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  Future<void> notifyAdoptionRequestApproved(String petName) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'adoption_approved_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Adoption Request Approved',
      body:
          'Congratulations! Your adoption request for $petName has been approved',
      type: NotificationType.adoption,
      createdAt: DateTime.now(),
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  // General Notifications
  Future<void> notifyGeneral(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    if (!_notificationsEnabled) return;

    final notification = NotificationData(
      id: 'general_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.general,
      createdAt: DateTime.now(),
      data: data,
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  // Emergency Notifications
  Future<void> notifyEmergency(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationData(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.emergency,
      createdAt: DateTime.now(),
      data: data,
    );

    await addNotification(notification);
    await showInstantNotification(
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationType type = NotificationType.general,
  }) async {
    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);
    final channelDescription = _getChannelDescription(type);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: _getImportance(type),
          priority: _getPriority(type),
          enableVibration: _vibrationEnabled,
          playSound: _soundEnabled,
          icon: '@mipmap/ic_launcher',
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _soundEnabled,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
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
      payload: payload,
    );
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'appointment_reminders';
      case NotificationType.healthRecord:
        return 'health_records';
      case NotificationType.vaccination:
        return 'vaccination_reminders';
      case NotificationType.adoption:
        return 'adoption_updates';
      case NotificationType.emergency:
        return 'emergency_alerts';
      case NotificationType.reminder:
        return 'general_reminders';
      case NotificationType.update:
        return 'app_updates';
      case NotificationType.general:
        return 'general_notifications';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'Appointment Reminders';
      case NotificationType.healthRecord:
        return 'Health Records';
      case NotificationType.vaccination:
        return 'Vaccination Reminders';
      case NotificationType.adoption:
        return 'Adoption Updates';
      case NotificationType.emergency:
        return 'Emergency Alerts';
      case NotificationType.reminder:
        return 'General Reminders';
      case NotificationType.update:
        return 'App Updates';
      case NotificationType.general:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'Notifications for upcoming appointments and appointment updates';
      case NotificationType.healthRecord:
        return 'Notifications about health record updates';
      case NotificationType.vaccination:
        return 'Reminders for upcoming vaccinations';
      case NotificationType.adoption:
        return 'Updates about adoption requests and approvals';
      case NotificationType.emergency:
        return 'Critical emergency alerts and urgent notifications';
      case NotificationType.reminder:
        return 'General reminders and notifications';
      case NotificationType.update:
        return 'App updates and new features';
      case NotificationType.general:
        return 'General notifications and updates';
    }
  }

  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return Importance.max;
      case NotificationType.appointment:
      case NotificationType.vaccination:
        return Importance.high;
      case NotificationType.adoption:
      case NotificationType.healthRecord:
        return Importance.defaultImportance;
      case NotificationType.reminder:
      case NotificationType.update:
      case NotificationType.general:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return Priority.max;
      case NotificationType.appointment:
      case NotificationType.vaccination:
        return Priority.high;
      case NotificationType.adoption:
      case NotificationType.healthRecord:
        return Priority.defaultPriority;
      case NotificationType.reminder:
      case NotificationType.update:
      case NotificationType.general:
        return Priority.low;
    }
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
    NotificationType type = NotificationType.general,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);
    final channelDescription = _getChannelDescription(type);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: _getImportance(type),
          priority: _getPriority(type),
          enableVibration: _vibrationEnabled,
          playSound: _soundEnabled,
          icon: '@mipmap/ic_launcher',
        );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _soundEnabled,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
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
    NotificationType type = NotificationType.general,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      type: type,
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Utility methods
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic for push notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // Get notification by ID
  NotificationData? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<NotificationData> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications by type
  List<NotificationData> getUnreadNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type && !n.isRead).toList();
  }

  // Search notifications
  List<NotificationData> searchNotifications(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _notifications
        .where(
          (n) =>
              n.title.toLowerCase().contains(lowercaseQuery) ||
              n.body.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }
}

int _safeHash(String input) {
  return input.hashCode.abs();
}

int _generateBaseNotificationId({
  required String appointmentId,
  String? fallbackKey,
}) {
  // Prefer real appointmentId when available (after Firestore creation)
  if (appointmentId.isNotEmpty) {
    return (_safeHash(appointmentId) % 100000) + 1000;
  }
  // Fallback to a composite key (petId-vetId-date) during pre-ID flows
  final key = (fallbackKey ?? DateTime.now().toIso8601String());
  return (_safeHash(key) % 100000) + 1000;
}
