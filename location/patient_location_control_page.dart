import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PatientLocationControlPage extends StatefulWidget {
  const PatientLocationControlPage({super.key});

  @override
  State<PatientLocationControlPage> createState() =>
      _PatientLocationControlPageState();
}

class _PatientLocationControlPageState
    extends State<PatientLocationControlPage> {
  final String patientUid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MapController mapController = MapController();

  bool consentGiven = false;
  bool trackingEnabled = false;

  LatLng? currentLocation;
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    loadPatientSettings();
    getInitialLocation();

    firestore
        .collection('patients_Location')
        .doc(patientUid)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final data = doc.data();
          if (data == null) return;

          bool isTracking = data['trackingEnabled'] ?? false;

          if (isTracking && consentGiven) {
            startTracking();
          } else {
            positionStream?.cancel();
          }
        });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // تحميل الإعدادات
  Future<void> loadPatientSettings() async {
    final doc =
        await firestore.collection('patients_Location').doc(patientUid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        consentGiven = data['consentGiven'] ?? false;
      });

      //  اقرأ حالة التتبع من الفاميلي
      bool isTracking = data['trackingEnabled'] ?? false;

      if (consentGiven && isTracking) {
        startTracking();
      }
    }
  }

  // إعطاء الموافقة
  Future<void> giveConsent() async {
    await firestore.collection('patients_Location').doc(patientUid).set({
      'consentGiven': true,
    }, SetOptions(merge: true));

    setState(() => consentGiven = true);
  }

  // تشغيل/إيقاف التتبع
  Future<void> toggleTracking(bool value) async {
    setState(() => trackingEnabled = value);

    await firestore.collection('patients_Location').doc(patientUid).set({
      'trackingEnabled': value,
    }, SetOptions(merge: true));

    if (value) {
      startTracking();
    } else {
      positionStream?.cancel();
    }
  }

  // التتبع في الخلفية + كل 2 متر
  void startTracking() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((pos) async {
      final latLng = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;

      setState(() {
        currentLocation = latLng;
      });

      // تحريك الخريطة على موقع المريض
      mapController.move(latLng, 18);

      await firestore.collection('patient_location').doc(patientUid).set({
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      

    });
  }



  Future<void> getInitialLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
  }
  // ========================
  // ==========================
  // ==================================================
  
  @override
  Widget build(BuildContext context) {
    if (!consentGiven) {
      return consentUI();
    }
    print("Patient Location============================= $currentLocation");

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Patient Location",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
      ),
      body: Column(
        children: [
         
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation ?? const LatLng(0, 0),
                initialZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.first_app",
                ),

                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget consentUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & Consent"),
        backgroundColor: const Color(0xFF1C621B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "We need your permission to access your location in order to "
              "monitor your safety and allow caregivers to track you.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: giveConsent,
              child: const Text("I Agree"),
            ),
          ],
        ),
      ),
    );
  }
}












// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geolocator/geolocator.dart';

// class PatientLocationControlPage extends StatefulWidget {
//   const PatientLocationControlPage({super.key});

//   @override
//   State<PatientLocationControlPage> createState() =>
//       _PatientLocationControlPageState();
// }

// class _PatientLocationControlPageState
//     extends State<PatientLocationControlPage> {
//   final String patientUid = FirebaseAuth.instance.currentUser!.uid;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final MapController mapController = MapController();

//   bool consentGiven = false;
//   bool trackingEnabled = false;

//   LatLng? currentLocation;
//   StreamSubscription<Position>? positionStream;

//   @override
//   void initState() {
//     super.initState();
//     loadPatientSettings();
//     getInitialLocation();

//     firestore
//         .collection('patients_Location')
//         .doc(patientUid)
//         .snapshots()
//         .listen((doc) {
//           if (!doc.exists) return;

//           final data = doc.data();
//           if (data == null) return;

//           bool isTracking = data['trackingEnabled'] ?? false;

//           if (isTracking && consentGiven) {
//             startTracking();
//           } else {
//             positionStream?.cancel();
//           }
//         });
//   }

//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }

//   // تحميل الإعدادات
//   Future<void> loadPatientSettings() async {
//     final doc =
//         await firestore.collection('patients_Location').doc(patientUid).get();

//     if (doc.exists) {
//       final data = doc.data()!;
//       setState(() {
//         consentGiven = data['consentGiven'] ?? false;
//       });

//       //  اقرأ حالة التتبع من الفاميلي
//       bool isTracking = data['trackingEnabled'] ?? false;

//       if (consentGiven && isTracking) {
//         startTracking();
//       }
//     }
//   }

//   // إعطاء الموافقة
//   Future<void> giveConsent() async {
//     await firestore.collection('patients_Location').doc(patientUid).set({
//       'consentGiven': true,
//     }, SetOptions(merge: true));

//     setState(() => consentGiven = true);
//   }

//   // تشغيل/إيقاف التتبع
//   Future<void> toggleTracking(bool value) async {
//     setState(() => trackingEnabled = value);

//     await firestore.collection('patients_Location').doc(patientUid).set({
//       'trackingEnabled': value,
//     }, SetOptions(merge: true));

//     if (value) {
//       startTracking();
//     } else {
//       positionStream?.cancel();
//     }
//   }

//   // ========================
//   // التتبع في الخلفية + كل 2 متر
//   // ========================
//   void startTracking() {
//     positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 2,
//       ),
//     ).listen((pos) async {
//       final latLng = LatLng(pos.latitude, pos.longitude);

//       if (!mounted) return;

//       setState(() {
//         currentLocation = latLng;
//       });

//       // تحريك الخريطة على موقع المريض
//       mapController.move(latLng, 18);

//       // حفظ الموقع في Firestore (سيستخدمه الكيرغيفر)
//       await firestore.collection('patient_location').doc(patientUid).set({
//         'latitude': latLng.latitude,
//         'longitude': latLng.longitude,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
      

//     });
//   }



//   Future<void> getInitialLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }

//     final pos = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     setState(() {
//       currentLocation = LatLng(pos.latitude, pos.longitude);
//     });
//   }
//   // ========================
//   // ==========================\
//   // ==================================================
  
//   @override
//   Widget build(BuildContext context) {
//     if (!consentGiven) {
//       return consentUI();
//     }
//     print("Patient Location============================= $currentLocation");

//     return Scaffold(
//       appBar: AppBar(
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text(
//           "Patient Location",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w900,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF1C621B),
//       ),
//       body: Column(
//         children: [
//           SwitchListTile(
//             title: const Text("Location Tracking"),
//             subtitle: const Text("Tracks location even in background"),
//             value: trackingEnabled,
//             onChanged: toggleTracking,
//             activeColor: const Color(0xFF1C621B),
//           ),
//           Expanded(
//             child: FlutterMap(
//               mapController: mapController,
//               options: MapOptions(
//                 initialCenter: currentLocation ?? const LatLng(0, 0),
//                 initialZoom: 18,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   userAgentPackageName: "com.example.first_app",
//                 ),

//                 if (currentLocation != null)
//                   MarkerLayer(
//                     markers: [
//                       Marker(
//                         point: currentLocation!,
//                         width: 40,
//                         height: 40,
//                         child: const Icon(
//                           Icons.person_pin_circle,
//                           color: Colors.blue,
//                           size: 35,
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget consentUI() {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Privacy & Consent"),
//         backgroundColor: const Color(0xFF1C621B),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               "We need your permission to access your location in order to "
//               "monitor your safety and allow caregivers to track you.",
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: giveConsent,
//               child: const Text("I Agree"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
