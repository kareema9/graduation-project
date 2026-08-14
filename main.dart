import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:first_app/homefunctional/care_rotin/notfication_routin.dart';
import 'package:first_app/homefunctional/medicationReminder/notfication_medication.dart';
import 'package:first_app/location/SafeZoneService.dart';
import 'package:first_app/location/notification_service.dart';
import 'package:first_app/navbar/navigator_page.dart';
import 'package:flutter/material.dart';
import 'package:first_app/auth/login_page.dart';
import 'package:first_app/auth/sing_up_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  await NotficationRoutin.init();
  await NotficationMedication.init();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

// =============================================================================
  // // ===============================
  final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // patientUid لازم تجلبه من Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userType = doc['userType'];
      String? patientUID ;

      if(userType == "caregiver"){
        final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid).get();
        patientUID = doc['patientUID'];

         // تشغيل الخدمة في الخلفية
      SafeZoneService(patientUid: patientUID);

      }

            


     
    }
  // // =================================
// ==============================================================================

//   // إنشاء channel للإشعارات عالية الأهمية

  //  تهيئة timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  // إنشاء channel للإشعارات عالية الأهمية
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alerts', // نفس الـ channelId في Function
    'Patient Alerts',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}


// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'alerts',
        'Patient Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// ======================================
getToken() async {
  String? mytoken = await FirebaseMessaging.instance.getToken();

  print("===========================token");
  print(mytoken);
}

// =================================
requestPermition() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

// =============================================
Future<void> saveUserToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  String uid = FirebaseAuth.instance.currentUser!.uid;

  print("===========================token");
  print(token);
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'fcmToken': token,
  }, SetOptions(merge: true));
}

// ====================================
Future<void> updateToken() async {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': newToken,
    });
  });
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    requestPermition();
    saveUserToken();

    // updateToken();
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Patient Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('================= User is currently signed out!');
      } else {
        print('================= User is signed in!');
      }
    });
  }

  // ==================================================
  // =============================================
  //
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home:
          (FirebaseAuth.instance.currentUser != null &&
                  FirebaseAuth.instance.currentUser!.emailVerified)
              ? NavigatorPage()
              : Login(),
      routes: {
        "singup": (context) => SingUp(),
        "login": (context) => Login(),
        
      },
    );
  }
}
