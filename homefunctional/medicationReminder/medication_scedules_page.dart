import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/homefunctional/medicationReminder/addmidication.dart';
import 'package:first_app/homefunctional/medicationReminder/notfication_medication.dart';
import 'package:first_app/homefunctional/medicationReminder/updatemedication.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class MedicationscedulesPage extends StatefulWidget {
  const MedicationscedulesPage({super.key});

  @override
  State<MedicationscedulesPage> createState() => _MedicationscedulesPageState();
}

class _MedicationscedulesPageState extends State<MedicationscedulesPage> {
  List<QueryDocumentSnapshot> medicalData = [];

  @override
  void initState() {
    super.initState();
    getMedical();
  }

  Future<void> getMedical() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection("Medication_Schedules")
            .where("id", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get();

    medicalData = snapshot.docs;
    setState(() {});
  }

  //  حذف المدكيشن
  Future<void> _deleteMedication(QueryDocumentSnapshot doc) async {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final int notificationId = data['notificationId'];

    // إلغاء الإشعارات
    final List days = data['days'];
    for (int i = 0; i < days.length; i++) {
      await NotficationMedication.cancelNotificationMedication(
        notificationId + i,
      );
    }

    // حذف من Firestore
    await FirebaseFirestore.instance
        .collection("Medication_Schedules")
        .doc(doc.id)
        .delete();

    getMedical();
  }

  //  تعديل المدكيشن
  Future<void> _editMedication(QueryDocumentSnapshot doc) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Updatemedication(medicationDoc: doc)),
    );

    if (result == true) {
      getMedical();
    }
  }

  //  تشغيل / إيقاف الإشعار
  Future<void> _toggleMedication(
    QueryDocumentSnapshot doc,
    bool isActive,
  ) async {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final int notificationId = data['notificationId'];

    await FirebaseFirestore.instance
        .collection("Medication_Schedules")
        .doc(doc.id)
        .update({"isActive": isActive});

    if (isActive) {
      await NotficationMedication.scheduleMedicationNotification(
        notificationId: notificationId,
        title: "Medication Reminder",
        body: data['name'],
        dateTime: tz.TZDateTime.from(
          (data['time'] as Timestamp).toDate(),
          tz.local,
        ),
        days: List<String>.from(data['days']),
      );
    } else {
      final List days = data['days'];
      for (int i = 0; i < days.length; i++) {
        await NotficationMedication.cancelNotificationMedication(
          notificationId + i,
        );
      }
    }

    getMedical();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Medication Reminders",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
        elevation: 2,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2C802A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedication()),
          );

          if (result == true) {
            getMedical();
          }
        },
      ),
      body:
          medicalData.isEmpty
              ? const Center(child: Text("No medications added yet"))
              : ListView.builder(
                itemCount: medicalData.length,
                itemBuilder: (context, index) {
                  //  التعريف الصحيح
                  final Map<String, dynamic> data =
                      medicalData[index].data() as Map<String, dynamic>;

                  final bool isActive = data['isActive'] ?? true;

                  final DateTime dateTime =
                      (data['time'] as Timestamp).toDate();

                  final String formattedTime =
                      "${dateTime.hour.toString().padLeft(2, '0')}:"
                      "${dateTime.minute.toString().padLeft(2, '0')}";

                  return Card(
                    color: const Color(0xFF2C802A),
                    child: ListTile(
                      // leading: const Icon(
                      //   Icons.medication,
                      //   color: Color(0xFFA5EC60),
                      // ),
                      title: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.medication,
                                color: Color(0xFFA5EC60),
                              ),
                              Text(
                                data['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Time: $formattedTime",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Days: ${(data['days'] as List).join(', ')}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            activeTrackColor: Color(0xFFA5EC60),
                            activeThumbColor: Colors.white,
                            value: isActive,
                            onChanged:
                                (value) => _toggleMedication(
                                  medicalData[index],
                                  value,
                                ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),

                            onSelected: (value) {
                              if (value == 'edit') {
                                _editMedication(medicalData[index]);
                              } else if (value == 'delete') {
                                _deleteMedication(medicalData[index]);
                              }
                            },
                            itemBuilder:
                                (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Text("Edit"),
                                        SizedBox(width: 8),
                                        Icon(Icons.edit),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Text("Delete"),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete, color: Colors.red),
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
              ),
    );
  }
}
