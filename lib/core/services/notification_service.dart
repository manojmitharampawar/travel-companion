import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:travel_companion/core/constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Reminder channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.reminderChannelId,
        AppConstants.reminderChannelName,
        description: 'Reminders about upcoming train journeys',
        importance: Importance.high,
      ),
    );

    // Alarm channel - highest priority
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.alarmChannelId,
        AppConstants.alarmChannelName,
        description: 'Alarm when approaching destination station',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    // Tracking channel - low priority persistent
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.trackingChannelId,
        AppConstants.trackingChannelName,
        description: 'Persistent notification during journey tracking',
        importance: Importance.low,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — navigate to journey screen
    // This will be connected via a callback or navigation service
  }

  /// Show a standard reminder notification
  static Future<void> showReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a persistent tracking notification
  static Future<void> showTrackingNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      AppConstants.trackingNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.trackingChannelId,
          AppConstants.trackingChannelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Show an alarm notification — full screen, loud, persistent
  static Future<void> showArrivalAlarm({
    required String stationName,
    required String estimatedTime,
  }) async {
    await _notifications.show(
      AppConstants.alarmNotificationId,
      'ARRIVING SOON!',
      'You are approaching $stationName. Estimated arrival: $estimatedTime',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alarmChannelId,
          AppConstants.alarmChannelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }

  /// Cancel a specific notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel the arrival alarm
  static Future<void> cancelAlarm() async {
    await _notifications.cancel(AppConstants.alarmNotificationId);
  }

  /// Show a "journey starting now" notification prompting to start tracking
  static Future<void> showJourneyStartNotification({
    required int journeyId,
    required String trainName,
    required String destinationCode,
  }) async {
    await _notifications.show(
      journeyId * 10 + 3,
      'Time to board! $trainName',
      'Your train is departing now. Tap to start journey tracking to $destinationCode.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.reminder,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
