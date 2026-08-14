import 'package:flutter/material.dart';

class EditQuestion extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditQuestion({super.key, required this.question});

  @override
  _EditQuestion createState() => _EditQuestion();
}

class _EditQuestion extends State<EditQuestion> {
  late TextEditingController questionController;
  late List<TextEditingController> optionControllers;
  late int optionsCount;
  late int correctIndex;

  @override
  void initState() {
    super.initState();

    questionController = TextEditingController(text: widget.question["text"]);

    optionsCount = widget.question["options"].length;
    correctIndex = widget.question["correctIndex"];

    optionControllers = List.generate(
      optionsCount,
      (i) => TextEditingController(text: widget.question["options"][i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 255, 255, 255),),
        title: Text(
          "Edit Question",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        
        backgroundColor: Color(0xFF1C621B),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            DropdownButtonFormField<int>(
              value: optionsCount,
              decoration: InputDecoration(
                labelText: "Number of Options",
                border: OutlineInputBorder(),
              ),
              items: [ 2, 3, 4, 5].map((e) {
                return DropdownMenuItem(value: e, child: Text("$e Options"));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  optionsCount = value!;

                  optionControllers = List.generate(
                    optionsCount,
                    (i) => i < widget.question["options"].length
                        ? TextEditingController(text: widget.question["options"][i])
                        : TextEditingController(),
                  );

                  if (correctIndex >= optionsCount) correctIndex = 0;
                });
              },
            ),

            SizedBox(height: 20),

            Column(
              children: List.generate(optionsCount, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: optionControllers[i],
                    decoration: InputDecoration(
                      labelText: "Option ${i + 1}",
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 20),

            DropdownButtonFormField<int>(
              value: correctIndex,
              decoration: InputDecoration(
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
              onChanged: (value) => setState(() => correctIndex = value!),
            ),

            SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1C621B),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
              child: Text("Save", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context, {
                  "text": questionController.text.trim(),
                  "options": optionControllers.map((c) => c.text.trim()).toList(),
                  "correctIndex": correctIndex,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
