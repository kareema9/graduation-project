import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/homefunctional/my_condition00.dart';
import 'package:flutter/material.dart';

class MyCondition extends StatefulWidget {
  const MyCondition({super.key});

  @override
  State<MyCondition> createState() => _MyCondition();
}

class _MyCondition extends State<MyCondition> {
  int? stageSystem;
  int? stageCaregiver;
  int? stageDoctor;
  int? stage;

  String? userType;
  String? patientUid;

  bool isLoading = true;
  bool hasAccess = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // ===================== LOAD DATA =====================
  Future<void> loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // -------- current user --------
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      userType = userDoc['userType'];

      // -------- PATIENT --------
      if (userType == 'patient') {
        patientUid = user.uid;
      }

      // -------- CAREGIVER --------
      else if (userType == 'caregiver') {
        hasAccess = userDoc['patientAccessApproved'] == true;

        if (!hasAccess) {
          setState(() => isLoading = false);
          return;
        }

        patientUid = userDoc['patientUID'];
        if (patientUid == null) {
          setState(() => isLoading = false);
          return;
        }
      } else {
        setState(() => isLoading = false);
        return;
      }

      // -------- PATIENT DATA --------
      final patientDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(patientUid)
          .get();

      if (!patientDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      stageSystem = patientDoc['stage_system'];
      stageDoctor = patientDoc['stage_doctor'];
      stageCaregiver = patientDoc['stage_caregiver'];

      evaluation(stageSystem!, stageCaregiver!, stageDoctor!);

      // update final stage فقط للمريض
      if (userType == 'patient') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(patientUid)
            .update({"stage": stage});
      }
    } catch (e) {
      print("Error loading condition: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  // ===================== EVALUATION =====================
  
  String evaluation(int stageSystem, int stageCaregiver, int stageDoctor) {
    if (stageSystem == stageDoctor && stageSystem == stageCaregiver) {
      stage = stageSystem;
      return "Great! The stages match. Stage: $stage";
    }

    if (stageDoctor != stageSystem && stageSystem == stageCaregiver) {
      stage = stageSystem;
      return "The system and caregiver assessments are similar, whereas the doctor’s assessment differs. Stage: $stage";
    }

    if (stageSystem != stageCaregiver && stageDoctor == stageSystem) {
      stage = stageSystem;
      return "The system and doctor assessments are similar, whereas the caregiver’s assessment differs. Stage: $stage";
    }

    if (stageDoctor == stageCaregiver && stageCaregiver != stageSystem) {
      stage = stageDoctor;
      return "The caregiver and doctor assessments are similar, whereas the system’s assessment differs. Stage: $stage";
    }

    // none match
    stage = max(stageDoctor, max(stageCaregiver, stageSystem));
    return "None of the assessments match. Stage: $stage";
  }


  // ===================== TEXT =====================
  String covariant(int stage) {
    if (stage == 0) {
      return "You are at a very early stage. You may notice occasional forgetfulness, but your daily life is not affected.";
    }
    if (stage == 1) {
      return "You may experience mild memory difficulties but can still manage daily activities independently.";
    }
    if (stage == 2) {
      return "Memory and thinking difficulties are noticeable and may require assistance in daily activities.";
    }
    return "Severe memory loss requiring continuous assistance with daily activities.";
  }

  String covariant1(int stage) {
    if (stage == 0) return "Stage 0\nVery Mild Memory Changes";
    if (stage == 1) return "Stage 1\nMild Cognitive Changes";
    if (stage == 2) return "Stage 2\nModerate Cognitive Decline";
    return "Stage 3\nSevere Cognitive Decline";
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    //  caregiver بدون صلاحية
    if (userType == 'caregiver' && !hasAccess) {
      return Scaffold(
       appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Patient Condition",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
      ),
        body: const Center(
          child: Text(
            "You do not have access to view the patient's condition.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Patient Condition",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  covariant1(stage!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C621B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  covariant(stage!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyCondition00()),
                    );
                  },
                  child: const Text("Details",
                  style: const TextStyle(
                     fontWeight: FontWeight.w500,
                    color: Color(0xFF1C621B),
                  ),),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
