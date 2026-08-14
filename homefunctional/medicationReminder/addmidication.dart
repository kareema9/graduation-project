import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:first_app/homefunctional/medicationReminder/notfication_medication.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class AddMedication extends StatefulWidget {
  final QueryDocumentSnapshot? medicationDoc;
  const AddMedication({super.key, this.medicationDoc});

  @override
  State<AddMedication> createState() => _AddMedicationState();
}

class _AddMedicationState extends State<AddMedication> {
  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  DateTime? selectedDateTime;
  List<String> selectedDays = [];

  CollectionReference medicationSchedules = FirebaseFirestore.instance
      .collection("Medication_Schedules");

  Future<void> addMedication(int notificationId) async {
    await medicationSchedules.add({
      "name": nameController.text.trim(),
      "days": selectedDays,
      "time": Timestamp.fromDate(selectedDateTime!),
      "id": FirebaseAuth.instance.currentUser!.uid,
      "notificationId": notificationId,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.medicationDoc != null) {
      final data = widget.medicationDoc!.data() as Map<String, dynamic>;

      nameController.text = data['name'];
      selectedDays = List<String>.from(data['days']);

      DateTime dateTime = (data['time'] as Timestamp).toDate();
      selectedDateTime = dateTime;

      timeController.text =
          "${dateTime.hour.toString().padLeft(2, '0')}:"
          "${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        final now = DateTime.now();

        // الوقت المحلي الذي اختاره المستخدم
        DateTime localDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // إذا الوقت ماضي => حطه لبكرة
        if (localDateTime.isBefore(now)) {
          localDateTime = localDateTime.add(const Duration(days: 1));
        }

        // خزنه UTC للفاريبيس
        selectedDateTime = localDateTime.toUtc();

        // عرض الوقت للمستخدم
        timeController.text =
            "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  
  final List<String> allDays = [
    "Saturday",
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Medication Schedule",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formState,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Medication Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: timeController,
                  readOnly: true,
                  onTap: () => pickTime(context),
                  decoration: const InputDecoration(
                    labelText: "Time",
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Select Days",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                Wrap(
                  spacing: 8,
                  children:
                      allDays.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              val
                                  ? selectedDays.add(day)
                                  : selectedDays.remove(day);
                            });
                          },
                        );
                      }).toList(),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    title: "Add Medication",
                    onPressed: () async {
                      if (!formState.currentState!.validate() ||
                          selectedDays.isEmpty ||
                          selectedDateTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all fields"),
                          ),
                        );
                        return;
                      }

                      try {
                        final int notificationId =
                            widget.medicationDoc != null
                                ? (widget.medicationDoc!.data()
                                    as Map<String, dynamic>)['notificationId']
                                : DateTime.now().millisecondsSinceEpoch ~/ 1000;

                        //  EDIT
                        if (widget.medicationDoc != null) {
                          // إلغاء الإشعار القديم
                          await NotficationMedication.cancelNotificationMedication(
                            notificationId,
                          );

                          await FirebaseFirestore.instance
                              .collection("Medication_Schedules")
                              .doc(widget.medicationDoc!.id)
                              .update({
                                "name": nameController.text.trim(),
                                "days": selectedDays,
                                "time": Timestamp.fromDate(selectedDateTime!),
                              });
                        }
                        //  ADD
                        else {
                          await addMedication(notificationId);
                        }

                        //  جدولة إشعار جديد
                        await NotficationMedication.scheduleMedicationNotification(
                          notificationId: notificationId,
                          title: "Medication Reminder",
                          body: nameController.text,
                          dateTime: tz.TZDateTime.from(
                            selectedDateTime!,
                            tz.local,
                          ), 
                          days: selectedDays,
                        );

                        
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
