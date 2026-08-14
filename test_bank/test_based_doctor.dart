import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TestBasedDoctor extends StatefulWidget {
  const TestBasedDoctor({super.key});

  @override
  State<TestBasedDoctor> createState() => _TestBasedDoctor();
}

class _TestBasedDoctor extends State<TestBasedDoctor> {
  int? selectedStage; // value selected in dialog
  final List<int> stageOptions = [1, 2, 3];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('userType', isEqualTo: 'patient')
                .snapshots(),

        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No patients found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var patient = snapshot.data!.docs[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF1C621B),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(patient['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stage : ${patient['stage_doctor'] ?? 'Not set'}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),

                    SizedBox(height: 4),
                    Text(patient['email'] ?? ""),
                  ],
                ),

                // subtitle: Text(patient['email'] ?? ""),
                trailing: Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF1C621B),
                ),

                onTap: () {
                  selectedStage = null; // reset before opening dialog

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          "Select Stage",
                          style: TextStyle(
                            color: Color(0xFF1C621B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        content: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: "Stage",
                            labelStyle: TextStyle(color: Color(0xFF1C621B)),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              stageOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text("Stage $s"),
                                    ),
                                  )
                                  .toList(),
                          value: selectedStage,
                          onChanged: (val) {
                            setState(() {
                              selectedStage = val;
                            });
                          },
                        ),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Color(0xFF1C621B)),
                            ),
                          ),

                          TextButton(
                            onPressed: () async {
                              if (selectedStage == null) return;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patient.id)
                                  .update({"stage_doctor": selectedStage});

                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF1C621B),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                "  Save  ",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  backgroundColor: Color(0xFF1C621B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
