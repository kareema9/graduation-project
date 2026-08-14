import 'package:first_app/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotficationMedication {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ---------------- INIT ----------------
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        // فتح شاشة المنبه
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          navigatorKey.currentState?.pushNamed('/alarm');
        }

        // STOP
        if (response.actionId == 'STOP') {
          final parts = response.payload!.split('|');
          final int id = int.parse(parts[0]);
          await flutterLocalNotificationsPlugin.cancel(id);
        }

        // SNOOZE 5 دقائق
        if (response.actionId == 'SNOOZE') {
          final parts = response.payload!.split('|');

          final int id = int.parse(parts[0]);
          final String title = parts[1];
          final String body = parts[2];

          await flutterLocalNotificationsPlugin.cancel(id);

          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title, // نفس اسم الدواء
            body, // نفس الوصف
            tz.TZDateTime.now(
              tz.local,
            ).add(const Duration(minutes: 5)), ////////////=====================
            _alarmDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: "$id|$title|$body",
          );
        }
      },
    );
  }

  // ---------------- ALARM STYLE ----------------
  static NotificationDetails _alarmDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        ticker: "Alarm",
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('STOP', 'STOP', showsUserInterface: true),
          AndroidNotificationAction(
            'SNOOZE',
            'SNOOZE',
            showsUserInterface: true,
          ),
        ],
      ),
    );
  }

  // ---------------- DAY → WEEKDAY ----------------
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

  // ---------------- NEXT TIME ----------------

  static tz.TZDateTime _nextInstanceOfWeekday(
    tz.TZDateTime dateTime,
    int weekday,
  ) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = dateTime;

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
  // static tz.TZDateTime _nextInstanceOfWeekday(
  //   int weekday,
  //   int hour,
  //   int minute,
  // ) {
  //   tz.TZDateTime now = tz.TZDateTime.now(tz.local);

  //   tz.TZDateTime scheduled = tz.TZDateTime(
  //     tz.local,
  //     now.year,
  //     now.month,
  //     now.day,
  //     hour,
  //     minute,
  //   );

  //   while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
  //     scheduled = scheduled.add(const Duration(days: 1));
  //   }

  //   return scheduled;
  // }

  // ---------------- SCHEDULE ----------------
  static Future<void> scheduleMedicationNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime dateTime,
    required List<String> days,
  }) async {
    for (int i = 0; i < days.length; i++) {
      final int weekday = _dayToWeekday(days[i]);
      final int id = notificationId + i;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfWeekday(tz.TZDateTime.from(dateTime, tz.local), weekday),
        _alarmDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: "$id|$title|$body",
      );
    }
  }

  // ---------------- CANCEL ----------------
  static Future<void> cancelNotificationMedication(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
