import 'package:first_app/component/buttonauth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityManagement extends StatefulWidget {
  const AvailabilityManagement({super.key});

  @override
  State<AvailabilityManagement> createState() => _AvailabilityManagement();
}

class _AvailabilityManagement extends State<AvailabilityManagement> {
  final String doctorUid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  int? selectedDay; //
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final Map<int, String> days = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday",
  };

  //  Pick Time
  Future<TimeOfDay?> pickTime() async {
    return await showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  // Add Weekly Slot
  Future<void> addWeeklySlot() async {
    if (selectedDay == null || startTime == null || endTime == null) return;

    final start =
        "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    final end =
        "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";

    await firestore
        .collection('doctor_availability')
        .doc(doctorUid)
        .collection('weekly_slots')
        .add({
          'dayOfWeek': selectedDay,
          'startTime': start,
          'endTime': end,
          'isActive': true,
        });

    setState(() {
      selectedDay = null;
      startTime = null;
      endTime = null;
    });
  }

  //======================AM ,PM
  String formatToAmPm(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];

    final isPm = hour >= 12;
    final period = isPm ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return "$hour:$minute $period";
  }

  //  UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Availability Management",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ==============Add Slot
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedDay,
                    hint: const Text(
                      "Select Day",
                      style: TextStyle(color: Color(0xFF1C621B)),
                    ),
                    items:
                        days.entries
                            .map(
                              (e) => DropdownMenuItem<int>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => selectedDay = val),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            startTime = await pickTime();
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),

                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            startTime == null
                                ? "Start Time"
                                : startTime!.format(context),
                            style: const TextStyle(
                              color: Color(0xFF1C621B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            endTime = await pickTime();
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),

                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            endTime == null
                                ? "End Time"
                                : endTime!.format(context),
                            style: const TextStyle(
                              color: Color(0xFF1C621B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: addWeeklySlot,
                      title: "Add Availability",
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =============Weekly Slots List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  firestore
                      .collection('doctor_availability')
                      .doc(doctorUid)
                      .collection('weekly_slots')
                      .orderBy('dayOfWeek')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No weekly availability yet"),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF1C621B),
                        ),
                        title: Text(
                          "${days[data['dayOfWeek']]}\n"
                          "${formatToAmPm(data['startTime'])} - "
                          "${formatToAmPm(data['endTime'])}",
                        ),

                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: data['isActive'],
                              activeColor: const Color.fromARGB(
                                255,
                                241,
                                242,
                                239,
                              ),
                              activeTrackColor: const Color(0xFF1C621B),
                              onChanged: (val) {
                                docs[index].reference.update({'isActive': val});
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            "Delete Availability",
                                          ),
                                          content: const Text(
                                            "Are you sure you want to delete this time slot?",
                                          ),

                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await docs[index].reference.delete();
                                  }
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("Delete"),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
