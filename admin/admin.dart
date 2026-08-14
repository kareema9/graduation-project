import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:first_app/admin/showuserpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==================== Admin Control Panel Page ====================
class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  // ========== Firebase Firestore Instance ==========
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Features List ==========
  final List<String> features = [
    'care_routine',
    'medication_reminders',
    'medical_records',
    'patient_location', //PatientLocation
    'media_gallery',
    'doctors_schedule', //DoctorsSchedule
    'test_bank',
    'my_condition',
    'family_tracking', //FamilyTracking
    'availability_management',
  ];

  // ========== Role Names ==========
  final Map<String, String> roleNames = {
    'patient': 'Patient',
    'doctor': 'Doctor',
    'caregiver': 'Caregiver',
  };

  // ========== Roles List ==========
  final List<String> roles = ['patient', 'doctor', 'caregiver'];

  // ========== Permissions Map ==========
  Map<String, Map<String, bool>> permissions = {};

  // ========== State Variables ==========
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  // ========== initState to load permissions ==========
  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  // ========== Load Permissions from Firestore ==========
  Future<void> _loadPermissions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final doc =
          await _firestore.collection('feature_control').doc('roles').get();
      if (doc.exists) {
        setState(() {
          permissions = {
            for (var role in roles)
              role: Map<String, bool>.from(doc.data()?[role] ?? {}),
          };
        });
      } else {
        Map<String, Map<String, bool>> defaultPermissions = {};
        for (var role in roles) {
          defaultPermissions[role] = {for (var f in features) f: false};
        }
        await _firestore
            .collection('feature_control')
            .doc('roles')
            .set(defaultPermissions);
        setState(() {
          permissions = defaultPermissions;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading permissions: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ========== Update Permission in Firestore ==========
  Future<void> _updatePermission(
    String role,
    String feature,
    bool value,
  ) async {
    setState(() {
      isUpdating = true;
      errorMessage = null;
      permissions[role]?[feature] = value;
    });

    try {
      await _firestore.collection('feature_control').doc('roles').set({
        role: permissions[role],
      }, SetOptions(merge: true));
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update permission: $e';
        permissions[role]?[feature] = !value;
      });
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  // ========== Helper to format feature names ==========
  String _prettyFeatureName(String feature) {
    return feature
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ========== Build Widget ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 30,
              color: Color(0xFF1C621B),
            ),
            SizedBox(width: 10),
            Text(
              "Admin Control Panel",
              style: TextStyle(
                color: Color(0xFF1C621B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        // Center the appBar title
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(height: 2, color: Color(0xFF1C621B)),
              const SizedBox(height: 30),

              // ========== Centered Header Text ==========
              Text(
                "Manage Feature Visibility by Role",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C621B), // Same green color
                ),
              ),

              const SizedBox(height: 15),

              // ========== Error Message Display ==========
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ========== Loading Indicator ==========
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1C621B),
                    ), // green spinner
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // padding: const EdgeInsets.all(16.0),
                  child: Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,

                          child: Center(
                            // Center the data table horizontally inside the scroll view
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFF419310),
                              ),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              //////////////////////===========  columnSpacing: 8,=================//////////////////////////////////
                              columnSpacing: 8,
                              columns: [
                                const DataColumn(label: Text("Feature")),
                                ...roles.map(
                                  (role) => DataColumn(
                                    label: Text(
                                      roleNames[role] ?? role,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows:
                                  features.map((feature) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            _prettyFeatureName(feature),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        ...roles.map((role) {
                                          return DataCell(
                                            Checkbox(
                                              fillColor:
                                                  MaterialStateProperty.all(
                                                    const Color(0xFF419310),
                                                  ),
                                              value:
                                                  permissions[role]?[feature] ??
                                                  false,
                                              onChanged:
                                                  isUpdating
                                                      ? null
                                                      : (val) {
                                                        _updatePermission(
                                                          role,
                                                          feature,
                                                          val ?? false,
                                                        );
                                                      },
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                        if (isUpdating)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black26,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF419310),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ----------------------------show all users button------------
              SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShowUserPage(),
                          ),
                        );
                      },

                      color: Color(0xFF1C621B),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "show all users",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              //-----------Logout---------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 30,
                ),
                child: Container(
                  child: TextButton(
                    onPressed: () {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.question,
                        animType: AnimType.rightSlide,
                        title: 'Confirm Logout',
                        desc: 'Do you really want to log out?',
                        btnOkText: "Logout",
                        btnCancelOnPress: () {},
                        btnOkOnPress: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil("login", (route) => false);
                        },
                      ).show();
                    },
                    child: Row(
                      children: [
                        Text(
                          "Logout ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Icon(
                          Icons.logout_sharp,
                          color: Colors.redAccent,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
