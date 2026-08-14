import 'package:first_app/test_bank/add_question_to_test3.dart';
import 'package:first_app/test_bank/edit_question.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestBasedCaregiver extends StatefulWidget {
  const TestBasedCaregiver({super.key});

  @override
  _TestBasedCaregiver createState() => _TestBasedCaregiver();
}

class _TestBasedCaregiver extends State<TestBasedCaregiver> {
  int selected = 0;
  Map<String, List<Map<String, dynamic>>> stageQuestions = {
    "daily_activities_assessment": [],
    "family_profile": [],
    "cognitive_assessment": [],
  };

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  // Load questions
  void loadQuestions() async {
    for (String stage in stageQuestions.keys) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("caregiver_test3")
              .doc(stage)
              .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> data = doc["questions"] ?? [];

        setState(() {
          stageQuestions[stage] =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    }
  }

  // Add Question

  Future<void> addQuestion(String stageKey) async {
    final newQuestion = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddQuestionToTest3(stageKey: stageKey)),
    );

    if (newQuestion != null) {
      setState(() {
        stageQuestions[stageKey]!.add(newQuestion);
      });
    }
  }

  // Edit Question
  Future<void> editQuestion(
    String stageKey,
    int index,
    Map<String, dynamic> question,
  ) async {
    final updatedQuestion = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditQuestion(question: question)),
    );

    if (updatedQuestion != null) {
      stageQuestions[stageKey]![index] = updatedQuestion;

      await FirebaseFirestore.instance
          .collection("caregiver_test3")
          .doc(stageKey)
          .update({"questions": stageQuestions[stageKey]});

      setState(() {});
    }
  }

  // Delete Question
  Future<void> deleteQuestion(String stageKey, int index) async {
    List<Map<String, dynamic>> updatedList = [...stageQuestions[stageKey]!];
    updatedList.removeAt(index);

    await FirebaseFirestore.instance
        .collection("caregiver_test3")
        .doc(stageKey)
        .update({"questions": updatedList});

    setState(() {
      stageQuestions[stageKey]!.removeAt(index);
    });
  }

  // Build Stage Block

  Widget stageBlock(String title, String stageKey, Widget icon) {
    return Card(
      // margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      // elevation: 7,
      // shadowColor: Color(0xFF1C621B),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: icon,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(width: 30),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 8,
                    thickness: 1,
                    color: Color(0xFF1C621B),
                  ),
        
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => addQuestion(stageKey),
        
                      icon: const Icon(Icons.add, size: 22),
        
                      label: const Text(
                        'Add Question',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
        
                          fontWeight: FontWeight.w700,
                        ),
                      ),
        
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1C621B),
                        iconColor: Color.fromARGB(255, 255, 255, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
        
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
        
                  // ================ add Question button ========================
                ],
              ),
        
              ...stageQuestions[stageKey]!.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> q = entry.value;
        
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Question text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q["text"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            ...List.generate(q["options"].length, (i) {
                              return Text(
                                "${i + 1}. ${q["options"][i]}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
        
                      // Dropdown Menu (edit / delete)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Color(0xFF1C621B)),
                        onSelected: (value) {
                          if (value == "edit") {
                            editQuestion(stageKey, index, q);
                          } else if (value == "delete") {
                            deleteQuestion(stageKey, index);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: "edit",
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 10),
                                    Text("Edit"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: "delete",
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text("Delete"),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: (value) {
              setState(() => selected = value);
            },

            backgroundColor: const Color(0xFF1C621B),
            selectedIconTheme: IconThemeData(color: Colors.grey[900], size: 30),
            unselectedIconTheme: const IconThemeData(
              color: Colors.white70,
              size: 26,
            ),
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedLabelTextStyle: TextStyle(color: Colors.white70),
            labelType: NavigationRailLabelType.all,
            indicatorShape: Border.all(),

            destinations: const [
              // 
             
              NavigationRailDestination(
                icon: Icon(Icons.task_alt),
                label: Text("Daily Activities\n Assessment\n"),
              ),
               // 
              NavigationRailDestination(
                icon: Icon(Icons.psychology),
                label: Text("  Cognitive\nAssessment\n"),
              ),


              // 
              NavigationRailDestination(
                icon: Icon(Icons.family_restroom),
                label: Text("Family Profile"),
              ),
            ],
          ),

          Expanded(
            child: IndexedStack(
              index: selected,
              children: [
                 // 0: Daily Activities
    Center(
      child: stageBlock(
        "Daily Activities\nAssessment",
        "daily_activities_assessment",
        Icon(Icons.task_alt, size: 28, color: Colors.green),
      ),
    ),

    // 1: Cognitive Assessment
    Center(
      child: stageBlock(
        "Cognitive\nAssessment",
        "cognitive_assessment",
        Icon(Icons.psychology, size: 28, color: Colors.green),
      ),
    ),

    // 2: Family Profile
    Center(
      child: stageBlock(
        "Family Profile",
        "family_profile",
        Icon(Icons.family_restroom, size: 28, color: Colors.green),
      ),
    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
