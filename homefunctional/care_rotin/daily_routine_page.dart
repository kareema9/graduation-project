import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/homefunctional/care_rotin/adddailyroutine.dart';
import 'package:first_app/homefunctional/care_rotin/editdailyroutine.dart';
import 'package:first_app/homefunctional/care_rotin/notfication_routin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyroutinePage extends StatefulWidget {
  const DailyroutinePage({super.key});

  @override
  State<DailyroutinePage> createState() => _DailyroutinePageState();
}

class _DailyroutinePageState extends State<DailyroutinePage> {
  Map<String, List<Map<String, dynamic>>> routinesByDay = {};

  @override
  void initState() {
    super.initState();
    getDailyRoutines();
  }

  Future<void> getDailyRoutines() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection("Daily_Routines")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get();

    Map<String, List<Map<String, dynamic>>> tempRoutines = {};

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String day = data["day"] ?? "Unknown";

      tempRoutines.putIfAbsent(day, () => []);

      tempRoutines[day]!.add({
        "id": doc.id,
        "activity": data["activity"] ?? "",
        "time": data["time"] ?? Timestamp.fromDate(DateTime.now()),
        "done": data["done"] ?? false,
      });
    }

    setState(() {
      routinesByDay = tempRoutines;
    });
  }

  Future<void> updateDoneStatus(String docId, bool newValue) async {
    await FirebaseFirestore.instance
        .collection("Daily_Routines")
        .doc(docId)
        .update({"done": newValue});
  }

  Future<void> deleteRoutine(String docId, int daysCount) async {
    // إلغاء كل إشعارات هذا الروتين
    await NotficationRoutin.cancelNotificationRoutine(
      docId.hashCode,
      daysCount,
    );

    await FirebaseFirestore.instance
        .collection("Daily_Routines")
        .doc(docId)
        .delete();

    getDailyRoutines();
  }
  
  void editRoutine(
    String docId,
    String currentActivity,
    String currentDay,
    String currentTime,
  ) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => EditDailyRoutine(
                  docId: docId,
                  currentActivity: currentActivity,
                  currentDay: currentDay,
                  currentTime: currentTime,
                ),
          ),
        )
        .then((value) {
          print('Returned from AddDailyRoutine with value: $value');

          if (value == true) {
            getDailyRoutines();
          }
        });
  }


  String _formatTimestamp(Timestamp timestamp) {
    DateTime dt = timestamp.toDate().toLocal();
    return DateFormat('hh:mm a').format(dt); // يعرض بصيغة 12 ساعة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Care Routine",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1C621B),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  routinesByDay.isEmpty
                      ? [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              "No daily routines yet.",
                              style: TextStyle(
                                color: Color(0xFF1C621B),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ]
                      : routinesByDay.keys.map((day) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: _buildDaySection(day),
                        );
                      }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1C621B),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AddDailyRoutine(),
                ),
              )
              .then((value) {
                if (value == true) {
                  getDailyRoutines();
                }
              });
        },
      ),
    );
  }

  Widget _buildDaySection(String day) {
    final routines = routinesByDay[day] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C621B),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children:
              routines.map((routine) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C621B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    // leading: Checkbox(
                    //   value: routine["done"],
                    //   activeColor: Colors.greenAccent,
                    //   checkColor: Colors.white,
                    //   onChanged: (val) {
                    //     setState(() {
                    //       routine["done"] = val!;
                    //     });
                    //     updateDoneStatus(routine["id"], val!);
                    //   },
                    // ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_activity, color: Colors.amber),
                            SizedBox(width: 10),
                            Text(
                              "${routine["activity"]}",
                              style: TextStyle(
                                color: Colors.amber,
                                decoration:
                                    routine["done"]
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            // Icon(Icons.access_time, color: Colors.white,),
                            Text(
                              "${_formatTimestamp(routine["time"])}",
                              style: TextStyle(
                                color: Colors.white,
                                decoration:
                                    routine["done"]
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          editRoutine(
                            routine["id"],
                            routine["activity"],
                            day,
                            _formatTimestamp(routine["time"]),
                          );
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text(
                                    'Confirm Delete',
                                    style: TextStyle(
                                      color: const Color(0xFF1C621B),
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this routine?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        deleteRoutine(
                                          routine["id"],
                                          1,
                                        ); // إذا الروتين يوم واحد
                                        // deleteRoutine(routine["id"]);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: const Color(0xFF1C621B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Text('Edit'),
                                  SizedBox(width: 8),
                                  Icon(Icons.edit),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Text('Delete'),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.red),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
