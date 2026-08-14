import 'package:flutter/material.dart';

class IconAuth extends StatelessWidget {
  const IconAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            "images/iconAD.png",
            width: 60,
            height: 60,
          ),
          
        ),

        Text(
          "AD care system",
          style: TextStyle(
            color: Color(0xFF1C621B),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
