import 'package:first_app/auth/login_page.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:flutter/material.dart';

class BlockingPage extends StatelessWidget {
  const BlockingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center( 
        child: Padding(
         
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Icon(Icons.block, color: Colors.red, size: 100),
              SizedBox(height: 20),
              Text(
                'Your account is temporarily deactivated.',
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Please contact support for more information.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 100),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    title: "To Login Page",
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                  ),
                ),
            ],
            
          ),
        ),
      ),
    );
  }
}
