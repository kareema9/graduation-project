import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotficationRoutin {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// تهيئة الإشعارات والمنطقة الزمنية
  static Future<void> init() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Gaza')); // أو 'Asia/Jerusalem'

    // إعدادات Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

 
  static int _dayToWeekday(String day) {
    switch (day) {
      case 'Sunday':
        return DateTime.sunday;
      case 'Monday':
        return DateTime.monday;
      case 'Tuesday':
        return DateTime.tuesday;
      case 'Wednesday':
        return DateTime.wednesday;
      case 'Thursday':
        return DateTime.thursday;
      case 'Friday':
        return DateTime.friday;
      case 'Saturday':
        return DateTime.saturday;
      default:
        return DateTime.monday;
    }
  }

  // --- حساب أقرب يوم ووقت محدد ---
  static tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // تأكد أن الوقت ليس في الماضي وأن اليوم صحيح
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// --- جدولة إشعار للأيام المحددة ---
  static Future<void> scheduleNotificationRoutine({
    required int notificationId,
    required String title,
    required String body,
    required DateTime dateTime, // الوقت المخزن UTC
    required List<String> days,
  }) async {
    for (int i = 0; i < days.length; i++) {
      final int weekday = _dayToWeekday(days[i]);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId + i, // ID مختلف لكل يوم
        title,
        body,
        _nextInstanceOfWeekday(weekday, dateTime.hour, dateTime.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelNotificationRoutine(
    int notificationId,
    int daysCount,
  ) async {
    for (int i = 0; i < daysCount; i++) {
      await flutterLocalNotificationsPlugin.cancel(notificationId + i);
    }
  }
}
