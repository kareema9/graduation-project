import 'dart:async';
import 'dart:convert';
import 'package:first_app/location/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SafeZone {
  final LatLng center;
  final double radius; // بالمتر

  SafeZone({required this.center, required this.radius});

  Map<String, dynamic> toMap() => {
    'lat': center.latitude,
    'lng': center.longitude,
    'radius': radius,
  };

  factory SafeZone.fromMap(Map<String, dynamic> map) => SafeZone(
    center: LatLng(map['lat'], map['lng']),
    radius: (map['radius'] as num).toDouble(),
  );
}

class CaregiverTrackingPage extends StatefulWidget {
  const CaregiverTrackingPage({super.key});

  @override
  State<CaregiverTrackingPage> createState() => _CaregiverTrackingPageState();
}

class _CaregiverTrackingPageState extends State<CaregiverTrackingPage> {
  LatLng? caregiverPosition;
  LatLng? patientPosition;
  String? patientUid;

  List<SafeZone> safeZones = [];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MapController mapController = MapController();
  final String caregiverUid = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription<Position>? caregiverStream;
  StreamSubscription<DocumentSnapshot>? patientStream;

  bool mapFitted = false;
  bool? isApproved;

  @override
  void initState() {
    super.initState();
    print("INIT STATE CALLED");

    Future.delayed(Duration.zero, () async {
      print("Calling startTrackingCaregiverLocation()");
      await startTrackingCaregiverLocation();
    });

    checkApproval().then((_) async {
      print("Approval check done: $isApproved");

      if (isApproved == true) {
        await loadPatientUidFromCaregiver();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showAddSafeZoneSnackBar();
        });
      }
    });
  }

  @override
  void dispose() {
    caregiverStream?.cancel();
    patientStream?.cancel();
    super.dispose();
  }

  // الشورتيست باث
  // ======================================================
  List<LatLng> routePoints = [];
  double? routeDistanceInMeters;

  Future<void> fetchShortestPath() async {
    if (caregiverPosition == null || patientPosition == null) return;

    final start = caregiverPosition!;
    final end = patientPosition!;

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // نقاط المسار
        final List coordinates = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          routePoints =
              coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        });

        // حساب طول الطريق
        double totalDistance = 0;
        for (int i = 0; i < routePoints.length - 1; i++) {
          totalDistance += Geolocator.distanceBetween(
            routePoints[i].latitude,
            routePoints[i].longitude,
            routePoints[i + 1].latitude,
            routePoints[i + 1].longitude,
          );
        }

        setState(() {
          routeDistanceInMeters = totalDistance;
        });
      }
    } catch (e) {
      print("Route error: $e");
    }
  }

  // snackbar
  void showAddSafeZoneSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C621B),
        content: const Row(
          children: [
            Icon(Icons.touch_app, color: Colors.white),
            SizedBox(width: 8),
            Text("Long press on the map\n to add a Safe Zone"),
          ],
        ),
        duration: const Duration(seconds: 6),

        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  //  Load patientUid linked to caregiver
  Future<void> loadPatientUidFromCaregiver() async {
    final doc = await firestore.collection('users').doc(caregiverUid).get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data == null || !data.containsKey('patientUID')) return;

    patientUid = data['patientUID'];
    listenToPatientLocation();
    listenToSafeZones();
    listenToTrackingStatus();
  }

  // TrackingStatus
  bool trackingEnabled = false;

  void listenToTrackingStatus() {
    if (patientUid == null) return;

    firestore
        .collection('patients_Location')
        .doc(patientUid)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final data = doc.data();
          if (data == null) return;

          setState(() {
            trackingEnabled = data['trackingEnabled'] ?? false;
          });
        });
  }

  // Enabel /disenable traking
  Future<void> togglePatientTracking(bool value) async {
    if (patientUid == null) return;

    setState(() {
      trackingEnabled = value;
    });

    await firestore.collection('patients_Location').doc(patientUid).set({
      'trackingEnabled': value,
    }, SetOptions(merge: true));
  }

  Future<void> startTrackingCaregiverLocation() async {
    print(" startTrackingCaregiverLocation called");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print(" Location services disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print(" Location permission denied");
      return;
    }

    print(" Location permission granted — getting first position...");

 
    Position firstPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(" First caregiver position fetched: $firstPos");

    if (!mounted) return;
    setState(
      () => caregiverPosition = LatLng(firstPos.latitude, firstPos.longitude),
    );

    print("📍 caregiverPosition set in state");

   
    caregiverStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      print(" Updated caregiver position: $pos");
      if (!mounted) return;
      setState(() => caregiverPosition = LatLng(pos.latitude, pos.longitude));

      fetchShortestPath(); // تحديث الطريق
    });
  }

  // Listen patient location
  void listenToPatientLocation() {
    if (patientUid == null) return;

    patientStream = firestore
        .collection('patient_location') // تأكد من اسم المجموعة
        .doc(patientUid)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final data = doc.data();
          if (data == null ||
              data['latitude'] == null ||
              data['longitude'] == null)
            return;

          if (!mounted) return;
          setState(() {
            patientPosition = LatLng(
              data['latitude'] as double,
              data['longitude'] as double,
            );
          });
          fetchShortestPath();
          checkSafeZones();
        });
  }

  // Listen safe zones
  void listenToSafeZones() {
    if (patientUid == null) return;

    firestore.collection('patients').doc(patientUid).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['safeZones'] == null) return;

      final List<dynamic> zonesData = data['safeZones'];
      setState(() {
        safeZones = zonesData.map((z) => SafeZone.fromMap(z)).toList();
      });
    });
  }

  // Add Safe Zone
  void addSafeZoneDialog(LatLng position) async {
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Safe Zone"),
            content: const Text("Do you want to add a safe zone here?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (confirm != true) return; 
   
    final TextEditingController controller = TextEditingController();
    bool validInput = false;

    while (!validInput) {
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Enter Safe Zone Radius (meters)"),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter a number between 2 and 1000",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null), // Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(controller.text), // Add
                  child: const Text("Add"),
                ),
              ],
            ),
      );

      if (result == null) return; 

      final radius = double.tryParse(result);
      if (radius == null || radius < 2 || radius > 1000) {
       
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Invalid input"),
                content: const Text(
                  "Please enter a number between 2 and 1000 meters.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
      
        validInput = true;

        final newZone = SafeZone(center: position, radius: radius);
        setState(() => safeZones.add(newZone));

        // حفظ Firestore
        if (patientUid != null) {
          await firestore.collection('patients').doc(patientUid).set({
            'safeZones': safeZones.map((z) => z.toMap()).toList(),
          }, SetOptions(merge: true));
        }
      }
    }
  }

  // delete afe zone
  void confirmDeleteSafeZone(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Safe Zone"),
            content: const Text("Do you want to delete this Safe Zone?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        safeZones.removeAt(index);
      });

      // تحديث Firestore بعد الحذف
      if (patientUid != null) {
        await firestore.collection('patients').doc(patientUid).set({
          'safeZones': safeZones.map((z) => z.toMap()).toList(),
        }, SetOptions(merge: true));
      }
    }
  }

  //  Approval check
  Future<void> checkApproval() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          isApproved = doc['patientAccessApproved'] == true;
        });
      } else {
        setState(() => isApproved = false);
      }
    } catch (e) {
      setState(() => isApproved = false);
      print("Error checking approval: $e");
    }
  }
  // ======================
// =================================
// ==========================
// دالة تحسب المسافة
bool isInsideZone(LatLng patient, SafeZone zone) {
  double distance = Geolocator.distanceBetween(
    patient.latitude,
    patient.longitude,
    zone.center.latitude,
    zone.center.longitude,
  );

  return distance <= zone.radius;
}
// دالة الإشعار
void sendAlertNotification() {
  NotificationService.showNotification(
    title: "Patient Alert !!!",
    body: "Patient left the safe zone!",
  );
}


// فحص الخروج من المناطق
bool alertSent = false;

void checkSafeZones() {
  if (patientPosition == null || safeZones.isEmpty) return;

  bool insideAnyZone = safeZones.any(
    (zone) => isInsideZone(patientPosition!, zone),
  );

  if (!insideAnyZone && !alertSent) {
    alertSent = true;
    sendAlertNotification();
  }

  if (insideAnyZone) {
    alertSent = false;
  }
}


  @override
  Widget build(BuildContext context) {
    if (isApproved == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isApproved == false) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Family Tracking",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1C621B),
        ),

        body: const Center(
          child: Text(
            "You do not have approval to view the patient's location.",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (caregiverPosition == null && patientPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final center = caregiverPosition ?? patientPosition!;
    print("pat==========================");
    print(patientPosition);
    print("caregiver==================");
    print(caregiverPosition);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Family Tracking",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Patient Location Tracking"),
            subtitle: const Text("Enable or disable patient's live location"),
            value: trackingEnabled,
            onChanged: togglePatientTracking,
            activeColor: const Color(0xFF1C621B),
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 16,
                    onLongPress: (tapPosition, point) {
                      addSafeZoneDialog(point); // فتح Dialog عند الضغط المطوّل
                    },
                  ),

                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.example.first_app",
                    ),

                    // عرض مناطق آمنة
                    if (safeZones.isNotEmpty) ...[
                      // عرض الدوائر
                      CircleLayer(
                        circles:
                            safeZones
                                .map(
                                  (zone) => CircleMarker(
                                    point: zone.center,
                                    radius: zone.radius,
                                    useRadiusInMeter: true,
                                    color: Colors.green.withOpacity(0.2),
                                    borderColor: Colors.green,
                                    borderStrokeWidth: 2,
                                  ),
                                )
                                .toList(),
                      ),

                      //  Shortest Path Line
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 5,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      // Markers غير مرئية لالتقاط الضغط
                      MarkerLayer(
                        markers:
                            safeZones.asMap().entries.map((entry) {
                              int index = entry.key;
                              SafeZone zone = entry.value;

                              return Marker(
                                point: zone.center,
                                width: 20,
                                height: 20,
                                child: GestureDetector(
                                  onTap: () => confirmDeleteSafeZone(index),
                                  child: Container(
                                    color: Colors.transparent, // غير مرئي
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],

                    // عرض المواقع
                    MarkerLayer(
                      markers: [
                        
                        if (caregiverPosition != null)
                          Marker(
                            point: caregiverPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.home,
                              color: Colors.orange,
                              size: 40,
                            ),
                          ),

                        if (patientPosition != null)
                          Marker(
                            point: patientPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.red,
                              size: 35,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // عرض المسافة أعلى الشاشة
                if (routeDistanceInMeters != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: Colors.white70,
                      child: Text(
                        "Route Distance: ${(routeDistanceInMeters! / 1000).toStringAsFixed(2)} km",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ====================
          ),
        ],
      ),
    );
  }
}
