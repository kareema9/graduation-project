import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/admin/admin.dart';
import 'package:first_app/location/caregiver_tracking_page.dart';
import 'package:first_app/location/patient_location_control_page.dart';
import 'package:first_app/homefunctional/availability_management.dart';
import 'package:first_app/homefunctional/my_condition.dart';
import 'package:first_app/test_bank/test_bank.dart';
import 'package:flutter/material.dart';
import 'package:first_app/homefunctional/appointment_booking.dart';
import 'package:first_app/homefunctional/care_rotin/daily_routine_page.dart';
import 'package:first_app/homefunctional/medical_record_page.dart';
import 'package:first_app/homefunctional/medicationReminder/medication_scedules_page.dart';
import 'package:first_app/homefunctional/photos_videos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  String? email;
  String? userType;
  String? name;
  bool isLoading = true;
  int? stage;
  User? user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> dashboardItems = [
    {"icon": Icons.medication, "title": "Medication Reminders"},
    {"icon": Icons.calendar_month, "title": "Doctors Schedule"},
    {"icon": Icons.photo, "title": "Media Gallery"},
    {"icon": Icons.location_on, "title": "Patient Location"},
    {"icon": Icons.receipt_long, "title": "Medical Records"},
    {"icon": Icons.access_time, "title": "Care Routine"},
    {"icon": Icons.star, "title": "Test Bank"},
    {"icon": Icons.assessment, "title": "Patient Condition"},
    {"icon": Icons.my_location, "title": "Family Traking"},
    {"icon": Icons.calendar_month_outlined, "title": "Availability Management"},
  ];

  List<Widget> get pages {
    return [
      MedicationscedulesPage(),
      BookingschedulesPage(),
      PhotosPage(),
      // LocationPage(patientUid: patientUid),
      PatientLocationControlPage(),
      MedicalRecordPage(),
      DailyroutinePage(),
      TestBank(),
      MyCondition(),
      // Tracking(familyUid: familyUid),
      CaregiverTrackingPage(),

      AvailabilityManagement(),
    ];
  }

  final List<String> features = [
    'medication_reminders',
    'doctors_schedule',
    'media_gallery',
    'patient_location',
    'medical_records',
    'care_routine',
    'test_bank',
    'my_condition',
    'family_tracking',
    'availability_management',
  ];

  Map<String, dynamic> featurePermissions = {};

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        email = userDoc['email'] as String?;
        name = userDoc['name'] as String?;
        userType = userDoc['userType'] as String?;
        stage = userDoc['stage'] as int? ?? 1;
      }

      // --- get permissions ---
      DocumentSnapshot roleDoc =
          await FirebaseFirestore.instance
              .collection('feature_control')
              .doc('roles')
              .get();

      if (roleDoc.exists) {
        featurePermissions = roleDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error loading user or permissions: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> getFilteredItems() {
    if (userType == null || featurePermissions.isEmpty) return [];

    Map<String, dynamic> typePerms = featurePermissions[userType] ?? {};
    List<Map<String, dynamic>> filtered = [];

    for (int i = 0; i < features.length; i++) {
      String featureKey = features[i];
      bool allowed = typePerms[featureKey] ?? false;
      if (allowed) {
        filtered.add(dashboardItems[i]);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Admin
    if (email == "1203332@student.birzeit.edu" ||
        email == "1200433@student.birzeit.edu") {
      return const Admin();
    } else {
      final filteredItems = getFilteredItems();

      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ==================== Header ====================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1C621B), Color(0xFF419310)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(25),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30.0,
                            backgroundImage: AssetImage("images/noProfile.jpg"),
                          ),
                          title: Text(
                            "Welcome, ${name ?? ''}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              userType == "patient"
                                  ? Row(
                                    children: List.generate(
                                      stage ?? 1,
                                      (index) => Icon(
                                        Icons.star,
                                        color: Colors.yellow[700],
                                        size: 20,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 22),
                      // ===================== Title =====================
                      if (userType == "patient")
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "We are with you every step of the way,\nTo help you feel safe and at ease.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1C621B),
                            ),
                          ),
                        ),

                      const SizedBox(height: 22),

                      // =================== Caregiver Requests ===================
                      if (userType == "patient" && user != null)
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('caregiver_requests')
                                  .where('patientUid', isEqualTo: user!.uid)
                                  .where('approved', isEqualTo: false)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "",
                                  // "No pending caregiver requests",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1C621B),
                                  ),
                                ),
                              );
                            }

                            final requests = snapshot.data!.docs;

                            return Column(
                              children: [
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: requests.length,
                                  itemBuilder: (context, index) {
                                    final request = requests[index];
                                    final caregiverUid = request.get(
                                      'caregiverUid',
                                    );
                                    final caregiverName = request.get(
                                      'caregiverEmail',
                                    );

                                    return Card(
                                      child: ListTile(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.notifications_active,
                                              color: Color(0xFF1C621B),
                                            ),
                                            SizedBox(width: 10),
                                            const Text(
                                              "Pending Caregiver Requests",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1C621B),
                                              ),
                                            ),
                                          ],
                                        ),

                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("$caregiverName wants access"),
                                            Text(
                                              "Date: ${request.get('createdAt') != null ? (request.get('createdAt') as Timestamp).toDate().toString() : ''}",
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Approve",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF1C621B,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.check,
                                                        color: Color(
                                                          0xFF1C621B,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        try {
                                                          // وافق المريض
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'caregiver_requests',
                                                              )
                                                              .doc(request.id)
                                                              .update({
                                                                'approved':
                                                                    true,
                                                              });

                                                          // إضافة الcaregiver عند المريض
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'users',
                                                              )
                                                              .doc(user!.uid)
                                                              .update({
                                                                'caregiverUID':
                                                                    caregiverUid,
                                                              });

                                                          // إضافة الpatient عند الcaregiver
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'users',
                                                              )
                                                              .doc(caregiverUid)
                                                              .update({
                                                                'patientUID':
                                                                    user!.uid,
                                                                'patientAccessApproved':
                                                                    true,
                                                              });
                                                        } catch (e) {
                                                          print(
                                                            "Error approving request: $e",
                                                          );
                                                        }
                                                      },
                                                    ),

                                                    SizedBox(width: 20),
                                                    Text(
                                                      "reject",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'caregiver_requests',
                                                            )
                                                            .doc(request.id)
                                                            .delete();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),

                      // ================== Grid Features ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                mainAxisExtent: 130,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, i) {
                            int originalIndex = dashboardItems.indexWhere(
                              (item) =>
                                  item["title"] == filteredItems[i]["title"],
                            );

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => pages[originalIndex],
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1C621B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        filteredItems[i]["icon"],
                                        size: 35,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      filteredItems[i]["title"],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1C621B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}


















