import 'package:first_app/test_bank/add_question_to_test1.dart';
import 'package:first_app/test_bank/edit_question.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestBasedSystem extends StatefulWidget {
  const TestBasedSystem({super.key});

  @override
  _TestBasedSystem createState() => _TestBasedSystem();
}

class _TestBasedSystem extends State<TestBasedSystem> {
  int selected = 0;
  Map<String, List<Map<String, dynamic>>> stageQuestions = {
    "executive": [],
    "naming": [],
    "attention": [],
    "language": [],
    "abstraction": [],
    "delayed recall": [],
    "orientation": [],
    "immediate memory": [],
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
              .collection("categories")
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
      MaterialPageRoute(builder: (_) => AddQuestionToTest1(stageKey: stageKey)),
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
          .collection("categories")
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
        .collection("categories")
        .doc(stageKey)
        .update({"questions": updatedList});

    setState(() {
      stageQuestions[stageKey]!.removeAt(index);
    });
  }

  // Build Stage Block

  Widget stageBlock(
    String title,
    String stageKey,
    Widget icon,
    Widget categorisText,
  ) {
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: categorisText,
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

  List<String> catrgorisText = [
    "Ability to plan, organize, solve problems, and follow complex steps.",
    "Ability to identify and name objects or images correctly.",
    "Ability to focus, concentrate, and maintain mental effort over time.",
    "Ability to understand, express, and process spoken or written language.",
    "Ability to recognize relationships between ideas and think conceptually.",
    "Ability to remember information after a period of time without cues.",
    "Awareness of time, place, and personal identity.",
    "Ability to instantly recall information presented seconds earlier.",
  ];
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

            selectedIconTheme: IconThemeData(color: Colors.grey[900], size: 20),

            unselectedIconTheme: const IconThemeData(
              color: Colors.white70,
              size: 18,
            ),
           selectedLabelTextStyle: TextStyle(fontSize: 10),
unselectedLabelTextStyle: TextStyle(fontSize: 8),
            labelType: NavigationRailLabelType.all,

            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),

            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.manage_accounts),
                label: Text("Executive"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.image_search),
                label: Text("Naming"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.center_focus_strong),
                label: Text("Attention"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.language),
                label: Text("Language"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text("Abstraction"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text("Delayed"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore),
                label: Text("Orientation"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.memory),
                label: Text("Memory"),
              ),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: selected,
              children: [
                Center(
                  child: stageBlock(
                    "Executive ",
                    "executive",
                    Icon(Icons.manage_accounts, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[0],
                      style: TextStyle(
                        color: Colors.grey[800],

                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Naming ",
                    "naming",
                    Icon(Icons.image_search, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[1],
                      style: TextStyle(
                        color: Colors.grey[800],

                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Attention ",
                    "attention",
                    Icon(
                      Icons.center_focus_strong,
                      size: 28,
                      color: Colors.green,
                    ),
                    Text(
                      catrgorisText[2],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Language ",
                    "language",
                    Icon(Icons.language, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[3],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Abstraction ",
                    "abstraction",
                    Icon(Icons.category, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[4],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Delayed\n Recall ",
                    "delayed recall",
                    Icon(Icons.history, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[5],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Orientation ",
                    "orientation",
                    Icon(Icons.explore, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[6],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stageBlock(
                    "Immediate\n  Memory ",
                    "immediate memory",
                    Icon(Icons.memory, size: 28, color: Colors.green),
                    Text(
                      catrgorisText[7],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
