import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuestionToTest1 extends StatefulWidget {
  final String stageKey;

  const AddQuestionToTest1({super.key, required this.stageKey});

  @override
  _AddQuestionToTest1 createState() => _AddQuestionToTest1();
}

class _AddQuestionToTest1 extends State<AddQuestionToTest1> {
  TextEditingController questionController = TextEditingController();

  int optionsCount = 2;
  List<TextEditingController> optionControllers = [TextEditingController(),TextEditingController(),];

  int correctIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 255, 255, 255),),
        title: Text(
          "Add Question",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        
        backgroundColor: Color(0xFF1C621B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Question field
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Number of options
            DropdownButtonFormField<int>(
              value: optionsCount,
              decoration: const InputDecoration(
                labelText: "Number of Options",
                border: OutlineInputBorder(),
              ),
              items: [ 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("$e Options"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  optionsCount = value!;
                  optionControllers = List.generate(
                    optionsCount,
                    (i) => TextEditingController(),
                  );
                  correctIndex = 0;
                });
              },
            ),

            const SizedBox(height: 20),

            // Options inputs
            Column(
              children: List.generate(optionsCount, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: optionControllers[index],
                    decoration: InputDecoration(
                      labelText: "Option ${index + 1}",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Correct option
            DropdownButtonFormField<int>(
              value: correctIndex,
              decoration: const InputDecoration(
                labelText: "Correct Option",
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                optionsCount,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text("Option ${i + 1}"),
                ),
              ),
              onChanged: (value) => setState(() {
                correctIndex = value!;
              }),
            ),

            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C621B),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: saveQuestion,
              child: const Text(
                "Save Question",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveQuestion() async {
    if (questionController.text.trim().isEmpty ||
        optionControllers.any((c) => c.text.trim().isEmpty)) {
      return;
    }

    Map<String, dynamic> newQ = {
      "text": questionController.text.trim(),
      "options": optionControllers.map((c) => c.text.trim()).toList(),
      "correctIndex": correctIndex,
    };

    await FirebaseFirestore.instance
        .collection("categories")
        .doc(widget.stageKey)
        .set({
      "questions": FieldValue.arrayUnion([newQ])
    }, SetOptions(merge: true));

    Navigator.pop(context, newQ);
  }
}
