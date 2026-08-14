import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/navbar/settings_page.dart';
import 'package:first_app/navbar/about_ad_page.dart';
import 'package:first_app/homefunctional/homa_page.dart';
import 'package:first_app/navbar/profile_page.dart';
import 'package:flutter/material.dart';

class NavPage extends StatefulWidget {
  final int initialIndex;
  const NavPage({super.key,this.initialIndex=0});

  @override
  State<NavPage> createState() => _NavPage();
}

class _NavPage extends State<NavPage> {
  int? status;
  bool isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;
  List<QueryDocumentSnapshot> userData = [];

  int selectedIndex = 0;
  List<Widget> pages = [
    HomePage(),
    ProfilePage(),
    SettingPage(),
    AboutAdPage(),
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    loadUserStatus();
    
  }
  //====function to get status user=======================
  Future<void> loadUserStatus() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      status = doc['status'] as int?;
      
    }
  } catch (e) {
    print("Error!!!!: $e");
  }

  setState(() {
    isLoading = false;
  });
}



  @override
  Widget build(BuildContext context) {
    
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


      return Scaffold(
        
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFA5EC60),
        selectedItemColor: Color(0xFF1C621B),
        unselectedItemColor: Color(0xFF419310),
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
}