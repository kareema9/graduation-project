import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/navbar/update_profile.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  String? phone;
  String? name;
  String? email;
  String? birthDate;
  int? stage;
  String? userType;

  bool isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;
  final String docid = FirebaseAuth.instance.currentUser!.uid;

  //====function to delete user==============================
  CollectionReference updateStatus = FirebaseFirestore.instance.collection(
    "users",
  );

  // FirebaseAuth.instance.currentUser!.uid
  deleteUser() async {
    await updateStatus.doc(docid).update({"status": 0});
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  List<QueryDocumentSnapshot> userData = [];
  // ===================================================== calculate age
  int calculateAge(String birthDateString) {
    DateTime birthDate = DateTime.parse(birthDateString);
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  String formatDateOnly(String dateTimeString) {
    return dateTimeString.split('T')[0];
  }

  Future<void> loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data() != null) {
        phone = doc['phone'] as String?;
        name = doc['name'] as String?;
        userType = doc['userType'] as String?;

        email = doc['email'] as String?;
        birthDate = doc['birthDate'] as String?;
        stage = doc['stage'] as int? ?? 1;
      }
    } catch (e) {
      print("Error!!!!: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFEAF7E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1C621B).withOpacity(0.4), width: 1),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C621B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF4FFF3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              
              // ---------------- PROFILE HEADER ----------------
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1C621B), Color(0xFF419310)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage("images/noProfile.jpg"),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "$name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    // STAGE STARS
                    if (userType == "patient")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          stage ?? 1,
                          (index) => Icon(
                            Icons.star_rounded,
                            color: Colors.yellowAccent,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              // ---------------- EDIT PROFILE BUTTON ----------------
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C621B),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditProfile(
                              docid: docid,
                              oldname: name,
                              oldphone: phone,
                              oldBirthDate: birthDate,
                            ),
                      ),
                    );
                  },
                  child: Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // ---------------- USER INFO SECTION ----------------
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    infoTile("Name", name ?? "N/A"),
                    infoTile("Phone", phone ?? "N/A"),
                    infoTile("Email", email ?? "N/A"),
                    
                  // if(userType =="patient")
                  //   infoTile("Stage",stage != null? "$stage": "Unknown",),
                    infoTile(
                      "Birth Date",
                      birthDate != null ? formatDateOnly(birthDate!) : "N/A",
                    ),
                    infoTile(
                      "Age",
                      birthDate != null
                          ? "${calculateAge(birthDate!)}"
                          : "Unknown",
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              //-----------Logout---------------------------------
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),

                child: TextButton(
                  onPressed: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.question,
                      animType: AnimType.rightSlide,
                      title: 'Confirm Logout',
                      desc: 'Are you sure you want to log out?',
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
              //-------------delete Account----------------
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),

                child: TextButton(
                  onPressed: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.question,
                      animType: AnimType.rightSlide,
                      title: 'Confirm Deactivate Account',
                      desc: 'Are you sure you want to deactivate this account?',
                      btnOkText: "Deactivate",
                      btnCancelOnPress: () {},
                      btnOkOnPress: () {
                        deleteUser();
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil("login", (route) => false);
                      },
                    ).show();
                  },
                  child: Row(
                    children: [
                      Text(
                        "Deactivate Account ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),

                      Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ],
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
