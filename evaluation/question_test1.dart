import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/evaluation/level_one.dart';
import 'package:flutter/material.dart';

class QuestionTest1 extends StatefulWidget {
  @override
  _QuestionTest1 createState() =>
      _QuestionTest1();
}

class _QuestionTest1
    extends State<QuestionTest1> {
  List<Map<String, dynamic>> questions = [];
  List<String?> answers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRandomQuestions();
  }

  //  Fetch categories  pick 1 random question from each
  Future<void> loadRandomQuestions() async {
    var categoriesSnap =
        await FirebaseFirestore.instance.collection("categories").get();

    List<Map<String, dynamic>> finalQ = [];

    for (var doc in categoriesSnap.docs) {
      List<dynamic> qList = doc["questions"] ?? [];

      if (qList.isNotEmpty) {
        final random = Random();
        var randQuestion = qList[random.nextInt(qList.length)];

        finalQ.add({
          "category": doc.id,
          "text": randQuestion["text"],
          "options": List<String>.from(randQuestion["options"]),
          "correctAnswer":
              randQuestion["options"][randQuestion["correctIndex"]],
        });
      }
    }

    setState(() {
      questions = finalQ;
      answers = List<String?>.filled(finalQ.length, null);
      loading = false;
    });
  }

  
 
  // Map of weights for each category
  final Map<String, int> categoryWeights = {
    "executive": 5,
    "naming": 3,
    "attention": 2,
    "language": 3,
    "abstraction": 2,
    "delayed recall": 5,
    "orientation": 6,
    "immediate memory": 4,
  };
//calcualte score/mark
  int calculateScore() {
    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i]["correctAnswer"]) {
        String category = questions[i]["category"];
        score += categoryWeights[category] ?? 0;
      }
    }

    return score;
  }

  //determend stage
  int getStageFromScore(int score) {
    if (score > 24) return 0; //stage 0
    if (score >= 17 && score <= 24) return 1; //stage 1
    if (score >= 11 && score <= 16) return 2; //stage 2
    return 3; //stage 3
  }

  // Submit
  void submit() async {
    if (answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please answer all questions before submitting."),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    int score = calculateScore();
    int stage = getStageFromScore(score);

    // Save to Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {"mark": score, "stage_system": stage, "timeTestOne": Timestamp.now(),
},
      );
    }
   
    if (score > 24) {//---True--->---homepage------------
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your score: $score → Stage: $stage"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Navigator()),
      );
    } else {//----False----->ReTest------------
      SnackBar(
        content: Text("Your score: $score → Stage: $stage"),
        backgroundColor: Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LevelOne()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      ///-------------------- app bar----------------------------
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Text(
            "Montreal Cognitive Assessment ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color(0xFF1C621B),
      ),
      //----------body--------------------------
      body:
          loading
              //---loading----------------
              ? Center(child: CircularProgressIndicator())
              //----Question---------------------
              : ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  var q = questions[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${q["text"]}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),

                          ...q["options"].map<Widget>((opt) {
                            return RadioListTile<String>(
                              title: Text(opt),
                              value: opt,
                              groupValue: answers[index],
                              activeColor: Color(0xFF1C621B),
                              onChanged: (val) {
                                setState(() {
                                  answers[index] = val;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),

      //---------submit button---------------------
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 50),
        child: ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1C621B),
            padding: EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text(
            "Submit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
