import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[100], // Warm colors
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 200,  // Adjust size as needed
            ),
            const SizedBox(height: 10),
            Text(
              "Welcome to ApricusLifestyle",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange[800]),
            ),
            Text(
              "Feel the warmth of the sun",
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.orange[600]),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text("Login"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[400]),
              child: Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
