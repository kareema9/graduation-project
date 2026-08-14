import 'package:flutter/material.dart';

class CustomTextForm extends StatelessWidget {
  final String labeltext;
  final TextEditingController mycontroller;
  final String? Function(String?)? validator;
  const CustomTextForm({super.key, required this.labeltext,required this.mycontroller,required this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: mycontroller,
      validator:validator ,
      decoration: InputDecoration(
        labelText: labeltext,
        filled: true,
        fillColor: Color(0xFFE1F3DF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
