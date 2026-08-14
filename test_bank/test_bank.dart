import 'package:first_app/test_bank/test_based_caregiver.dart';
import 'package:first_app/test_bank/test_based_doctor.dart';
import 'package:first_app/test_bank/test_based_system.dart';
import 'package:flutter/material.dart';

class TestBank extends StatefulWidget {
  const TestBank({super.key});

  @override
  State<TestBank> createState() => _TestBank();
}

class _TestBank extends State<TestBank> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  // =============================================================================
  TabController? tabController;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Test Bank",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(55),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),

            child: TabBar(
              controller: tabController,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,

              indicatorColor: Color(0xFFA5EC60),
              indicatorWeight: 5,
              tabs: [
                Tab(text: "     Test 1     "),
                Tab(text: "     Test 2     "),
                Tab(text: "     Test 3     "),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: [
          TestBasedSystem(),
          TestBasedDoctor(),
          // VerticalRailTabs(),
          TestBasedCaregiver(),
        ],
      ),
    );
  }
}
