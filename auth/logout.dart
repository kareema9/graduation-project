import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogOut extends StatelessWidget {
  const LogOut({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil("login", (route) => false);
      },
      child: Row(
        children: [
          Text(
            "Logout ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          Icon(Icons.logout_sharp, color: Colors.redAccent, size: 26),
        ],
      ),
    );
   
  }
}
