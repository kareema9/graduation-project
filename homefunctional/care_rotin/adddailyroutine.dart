import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/homefunctional/care_rotin/notfication_routin.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class AddDailyRoutine extends StatefulWidget {
  const AddDailyRoutine({super.key});

  @override
  State<AddDailyRoutine> createState() => _AddDailyRoutineState();
}

class _AddDailyRoutineState extends State<AddDailyRoutine> {
  final TextEditingController activityController = TextEditingController();

  String selectedDay = "Sunday";
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> days = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> addRoutine() async {
    if (activityController.text.isEmpty) return;

    // الوقت المحلي الذي اختاره المستخدم
    DateTime now = DateTime.now();
    DateTime routineTimeLocal = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    //  نحول الوقت المحلي إلى UTC للتخزين في Firebase
    DateTime routineTimeUtc = routineTimeLocal.toUtc();

    //  حفظ الروتين في Firebase بصيغة UTC
    DocumentReference doc = await FirebaseFirestore.instance
        .collection("Daily_Routines")
        .add({
          "userId": FirebaseAuth.instance.currentUser!.uid,
          "activity": activityController.text,
          "day": selectedDay,
          "time": Timestamp.fromDate(routineTimeUtc),
          "done": false,
        });

    // جدولة الإشعار باستخدام timezone المحلي
   
    await NotficationRoutin.scheduleNotificationRoutine(
      notificationId: doc.id.hashCode, // ID فريد
      title: "Care Routine Reminder",
      body: activityController.text,
      dateTime: tz.TZDateTime.from(routineTimeUtc, tz.local),
      days: [selectedDay],
    );

    Navigator.of(context).pop(true);
  }

  

  String formatTime(TimeOfDay t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Routine"),
        backgroundColor: const Color(0xFF1C621B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: activityController,
              decoration: const InputDecoration(labelText: "Activity Name"),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: selectedDay,
              items:
                  days
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) => setState(() => selectedDay = val!),
              decoration: const InputDecoration(labelText: "Select Day"),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Text("Time: ${formatTime(selectedTime)}")),
                ElevatedButton(
                  onPressed: pickTime,
                  child: const Text("Pick Time"),
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: addRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C621B),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Routine"),
            ),
          ],
        ),
      ),
    );
  }
}
