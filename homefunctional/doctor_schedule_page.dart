import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorSchedulePage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorSchedulePage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  List<Map<String, dynamic>> schedules = [];

  final Map<int, String> daysMap = {
    1: "Saturday",
    2: "Sunday",
    3: "Monday",
    4: "Tuesday",
    5: "Wednesday",
    6: "Thursday",
    7: "Friday",
  };

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    final snapshot =
        await firestore
            .collection('doctor_availability')
            .doc(widget.doctorId)
            .collection('weekly_slots')
            .where('isActive', isEqualTo: true)
            .get();

    schedules =
        snapshot.docs.map((d) {
          return {
            'dayOfWeek': d['dayOfWeek'],
            'start': d['startTime'],
            'end': d['endTime'],
          };
        }).toList();

    setState(() => isLoading = false);
  }

  Future<void> bookAppointment(int dayOfWeek, String start) async {
    DateTime now = DateTime.now();
    int diff = dayOfWeek - now.weekday;
    if (diff < 0) diff += 7;

    DateTime date = now.add(Duration(days: diff));

    await firestore.collection('appointments').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'doctorId': widget.doctorId,
      'doctorName': widget.doctorName,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'time': start,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Appointment booked")));
  }

  // دالة لتحويل الوقت من 24 ساعة إلى 12 ساعة مع AM/PM
  String formatTimeWithAmPm(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];

    String period = "AM";
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.doctorName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FixedColumnWidth(80),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    /// ===== Header =====
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Day",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Available Times",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    /// ===== Rows =====
                    ...daysMap.entries.map((day) {
                      final daySlots =
                          schedules
                              .where((s) => s['dayOfWeek'] == day.key)
                              .toList();

                      if (daySlots.isEmpty) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(day.value),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                "—",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        );
                      }

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              day.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  daySlots.map((slot) {
                                    return GestureDetector(
                                      onTap:
                                          () => bookAppointment(
                                            day.key,
                                            slot['start'],
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            163,
                                            235,
                                            170,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "${formatTimeWithAmPm(slot['start'])} - ${formatTimeWithAmPm(slot['end'])}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}