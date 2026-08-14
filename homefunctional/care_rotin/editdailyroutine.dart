import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/homefunctional/care_rotin/notfication_routin.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class EditDailyRoutine extends StatefulWidget {
  final String docId;
  final String currentActivity;
  final String currentDay;
  final String currentTime;

  const EditDailyRoutine({
    super.key,
    required this.docId,
    required this.currentActivity,
    required this.currentDay,
    required this.currentTime,
  });

  @override
  State<EditDailyRoutine> createState() => _EditDailyRoutineState();
}

class _EditDailyRoutineState extends State<EditDailyRoutine> {
  late TextEditingController activityController;

  late String selectedDay;
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

  @override
  void initState() {
    super.initState();
    activityController = TextEditingController(text: widget.currentActivity);
    selectedDay = widget.currentDay;
    selectedTime = _parseTime(widget.currentTime);
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(" ");
    final time = parts[0].split(":");
    int hour = int.parse(time[0]);
    int minute = int.parse(time[1]);

    if (parts[1] == "PM" && hour != 12) hour += 12;
    if (parts[1] == "AM" && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> updateRoutine() async {
    // الوقت المحلي الذي اختاره المستخدم
    DateTime now = DateTime.now();
    DateTime newTimeLocal = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    //  تحويل الوقت المحلي إلى UTC للتخزين
    DateTime newTimeUtc = newTimeLocal.toUtc();

    

    await NotficationRoutin.cancelNotificationRoutine(widget.docId.hashCode, 1);
    //  تحديث فايربيز بصيغة UTC
    await FirebaseFirestore.instance
        .collection("Daily_Routines")
        .doc(widget.docId)
        .update({
          "activity": activityController.text,
          "day": selectedDay,
          "time": Timestamp.fromDate(newTimeUtc),
        });

    //  جدولة إشعار جديد باستخدام Local timezone
    await NotficationRoutin.scheduleNotificationRoutine(
      notificationId: widget.docId.hashCode,
      title: "Care Routine Reminder",
      body: activityController.text,
      dateTime: tz.TZDateTime.from(newTimeUtc, tz.local), // ⚡ مهم
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Routine",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
        elevation: 0,
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
                  child: const Text(
                    "Pick Time",
                    style: TextStyle(color: Color(0xFF1C621B)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: updateRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C621B),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Routine",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
