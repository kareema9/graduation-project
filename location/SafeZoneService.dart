import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:first_app/location/notification_service.dart';
import 'package:latlong2/latlong.dart';

class SafeZone {
  final LatLng center;
  final double radius;

  SafeZone({required this.center, required this.radius});
}

class SafeZoneService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String? patientUid;

  LatLng? patientPosition;
  List<SafeZone> safeZones = [];
  bool alertSent = false;

  StreamSubscription<DocumentSnapshot>? patientStream;

  SafeZoneService({required this.patientUid}) {
    listenToPatientLocation();
    listenToSafeZones();
  }

  void listenToPatientLocation() {
    if (patientUid == null) return;

    patientStream = firestore
        .collection('patient_location')
        .doc(patientUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null ||
          data['latitude'] == null ||
          data['longitude'] == null) return;

      patientPosition = LatLng(data['latitude'], data['longitude']);
      checkSafeZones();
    });
  }

  void listenToSafeZones() {
    if (patientUid == null) return;

    firestore.collection('patients').doc(patientUid).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['safeZones'] == null) return;

      final List<dynamic> zonesData = data['safeZones'];
      safeZones = zonesData.map((z) => SafeZone(
            center: LatLng(z['lat'], z['lng']),
            radius: (z['radius'] as num).toDouble(),
          )).toList();
    });
  }

  bool isInsideZone(LatLng patient, SafeZone zone) {
    double distance = Geolocator.distanceBetween(
      patient.latitude,
      patient.longitude,
      zone.center.latitude,
      zone.center.longitude,
    );
    return distance <= zone.radius;
  }

  void checkSafeZones() {
    if (patientPosition == null || safeZones.isEmpty) return;

    bool insideAnyZone = safeZones.any(
      (zone) => isInsideZone(patientPosition!, zone),
    );

    if (!insideAnyZone && !alertSent) {
      alertSent = true;
      NotificationService.showNotification(
        title: "Patient Alert",
        body: "Patient left the safe zone!",
      );
    }

    if (insideAnyZone) {
      alertSent = false;
    }
  }

  void dispose() {
    patientStream?.cancel();
  }
}
