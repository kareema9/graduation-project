import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/auth/login_page.dart';
import 'package:first_app/admin/blockingpage.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:first_app/evaluation/question_test1.dart';
import 'package:first_app/evaluation/question_test3.dart';
import 'package:first_app/navbar/settings_page.dart';
import 'package:first_app/navbar/about_ad_page.dart';
import 'package:first_app/homefunctional/homa_page.dart';
import 'package:first_app/navbar/profile_page.dart';
import 'package:flutter/material.dart';

class NavigatorPage extends StatefulWidget {
  final int initialIndex;
  NavigatorPage({super.key, this.initialIndex = 0});

  @override
  State<NavigatorPage> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> {
  int? status;
  String? userType;
  bool? hasAccess;
  bool isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;
  List<QueryDocumentSnapshot> userData = [];
  bool shouldShowTest1 = false;
  bool shouldShowTest3 = false;
  Timer? testTimer;

  int selectedIndex = 0;
  List<Widget> pages = [
    HomePage(),
    ProfilePage(),
    SettingPage(),
    AboutAdPage(),
  ];

  //====function to get status user=======================
  Future<void> loadUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data() != null) {
        status = doc['status'] as int?;
        userType = doc['userType'] as String?;
        hasAccess = doc['patientAccessApproved'] as bool?;
        //   عشان لوب الاسئلة للمريض
        // ========================

        // نجيب وقت آخر اختبار
        if (userType == "patient") {
          Timestamp? lastTestTime = doc['timeTestOne'];
          if (lastTestTime != null) {
            DateTime lastTime = lastTestTime.toDate();
            DateTime now = DateTime.now();

            print("Last test: $lastTime");
            print("Now: $now");

            // كل ثلاثين يوم
            Duration difference = now.difference(lastTime);

            if (difference.inDays >= 30) {
              shouldShowTest1 = true;
            } else {
              shouldShowTest1 = false;
            }
          } else {
            // أول مرة
            shouldShowTest1 = true;
          }
          //   عشان لوب الاسئلة للفاميلي
          // ========================
        } else if (userType == "caregiver") {
          String? patintuid;
          Timestamp? lastTest3Time;
          patintuid = doc['patientUID'];
          // ===
          User? user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          try {
            DocumentSnapshot doc =
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(patintuid)
                    .get();

            if (doc.exists && doc.data() != null) {
              lastTest3Time = doc['timeTestThree'];
            }
          } catch (e) {
            print("Error!!!!: $e");
          }
          // ====

          if (lastTest3Time != null) {
            DateTime lastTime = lastTest3Time.toDate();
            DateTime now = DateTime.now();

            print("Last test: $lastTime");
            print("Now: $now");

            // كل ثلاثين يوم
            Duration difference = now.difference(lastTime);

            if (difference.inDays >= 30) {
              shouldShowTest3 = true;
            } else {
              shouldShowTest3 = false;
            }
          } else {
            // أول مرة
            shouldShowTest3 = true;
          }
        }
      }
    } catch (e) {
      print("Error!!!!: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    loadUserStatus();

    // يفحص كل يوم
    testTimer = Timer.periodic(Duration(days: 1), (timer) {
      loadUserStatus();
    });
  }

  @override
  void dispose() {
    testTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    //----if status is 1 return navigator page-------
    if (status == 1) {
      print("status:======$status");
      //  && shouldShowTest1
      if (shouldShowTest1 && userType == "patient") {
        print("qus1111111111111111111111111111");
        return QuestionTest1();
      } else if (userType == "caregiver" && shouldShowTest3) {
        if (hasAccess == true) {
          return QuestionTest3();
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 200,
                horizontal: 30,
              ),
              child: Column(
                children: [
                  const Text(
                    "You do not have access to view the patient's condition.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 100),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      title: "To Login Page",
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Color(0xFFA5EC60),
            selectedItemColor: Color(0xFF1C621B),
            unselectedItemColor: Color.fromARGB(255, 62, 141, 16),
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: (val) {
              setState(() {
                selectedIndex = val;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_2_rounded),
                label: "Profile",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_sharp),
                label: "About AD",
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(index: selectedIndex, children: pages),
          ),
        );
      }

      //----if status is not 1 return Blocking page-------
    } else {
      print("status:======$status");
      return BlockingPage();
    }
  }
}














