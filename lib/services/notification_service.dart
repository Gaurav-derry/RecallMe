import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../data/models/reminder.dart';

/// Local Notification Service for reminders and routines
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Set local timezone (default to UTC if not available)
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Indian timezone
    } catch (e) {
      debugPrint('Timezone error: $e, using UTC');
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _isInitialized =
        await _notifications.initialize(
          settings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        ) ??
        false;

    // Request permissions on Android 13+
    await _requestPermissions();

    debugPrint('NotificationService initialized: $_isInitialized');
  }

  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // Request notification permission
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Notification permission granted: $granted');

      // Request exact alarm permission for Android 12+
      final exactAlarmGranted =
          await androidPlugin.requestExactAlarmsPermission();
      debugPrint('Exact alarm permission granted: $exactAlarmGranted');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'test',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🔔 Test Notification',
      'Notifications are working! You will receive routine reminders.',
      details,
    );

    debugPrint('Test notification shown');
  }

  /// Schedule a notification for a reminder
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized for reminder');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

    // Don't schedule if the time has passed
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Reminder time has passed, not scheduling');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.description.isNotEmpty
          ? reminder.description
          : 'Time for your reminder!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );

    debugPrint('Reminder scheduled for: $scheduledDate');

    // Schedule repeating reminders
    if (reminder.repeatType != RepeatType.none) {
      await _scheduleRepeating(reminder, scheduledDate, details);
    }
  }

  Future<void> _scheduleRepeating(
    Reminder reminder,
    tz.TZDateTime startDate,
    NotificationDetails details,
  ) async {
    DateTimeComponents? matchComponents;

    switch (reminder.repeatType) {
      case RepeatType.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case RepeatType.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case RepeatType.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case RepeatType.none:
        return;
    }

    await _notifications.zonedSchedule(
      '${reminder.id}_repeat'.hashCode,
      reminder.title,
      reminder.description.isNotEmpty
          ? reminder.description
          : 'Time for your reminder!',
      startDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
      payload: reminder.id,
    );
  }

  /// Cancel a scheduled notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Cancelled notification: $id');
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminder(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
    await _notifications.cancel('${reminderId}_repeat'.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Schedule a one-time notification at a specific time
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return false;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    debugPrint('Scheduling notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Scheduled: $tzScheduledTime');
    debugPrint('  Now: $now');

    if (tzScheduledTime.isBefore(now)) {
      debugPrint('  SKIPPED: Time has passed');
      return false;
    }

    const androidDetails = AndroidNotificationDetails(
      'routines',
      'Routines',
      channelDescription: 'Routine notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('  SUCCESS: Notification scheduled');
      return true;
    } catch (e) {
      debugPrint('  ERROR: $e');
      return false;
    }
  }

  /// Schedule a daily notification at a specific time
  Future<bool> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('Scheduling DAILY notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Time: $hour:$minute');
    debugPrint('  First trigger: $scheduledDate');

    const androidDetails = AndroidNotificationDetails(
      'routines',
      'Routines',
      channelDescription: 'Routine notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('  SUCCESS: Daily notification scheduled');
      return true;
    } catch (e) {
      debugPrint('  ERROR: $e');
      return false;
    }
  }

  /// Schedule a weekly notification at a specific day and time
  Future<bool> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Find the next occurrence of the weekday
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('Scheduling WEEKLY notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Weekday: $weekday, Time: $hour:$minute');
    debugPrint('  First trigger: $scheduledDate');

    const androidDetails = AndroidNotificationDetails(
      'routines',
      'Routines',
      channelDescription: 'Routine notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
      debugPrint('  SUCCESS: Weekly notification scheduled');
      return true;
    } catch (e) {
      debugPrint('  ERROR: $e');
      return false;
    }
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('Immediate notification shown: $title');
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    for (final n in pending) {
      debugPrint('  - ID: ${n.id}, Title: ${n.title}');
    }
    return pending;
  }
}
