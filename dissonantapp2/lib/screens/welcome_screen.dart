import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/welcome_background.png',  // Path to your background image
              fit: BoxFit.cover,        // Make the image cover the whole screen
            ),
          ),
          // Foreground content
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 2),  // Add space above the logo
                  // Logo and text side by side
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/dissonantlogo.png',  // Path to your logo image
                        height: 70,  // Make the logo much smaller
                      ),
                      SizedBox(width: 8.0),  // Add some space between the logo and text
                      Text(
                        'Dissonant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 72,  // Make the text much bigger
                          fontWeight: FontWeight.bold,
                          color: Colors.white,  // Text color
                        ),
                      ),
                    ],
                  ),
                  Spacer(flex: 1),  // Add flexible space between the text and buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,  // Button background color
                      side: BorderSide(color: Colors.orange, width: 2),  // Orange outline
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,  // Sharp rectangle
                      ),
                      minimumSize: Size(200, 50), // Make button slimmer
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.white),  // Text color to match outline
                    ),
                  ),
                  SizedBox(height: 16.0),  // Add some space between the buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,  // Button background color
                      side: BorderSide(color: Colors.orange, width: 2),  // Orange outline
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,  // Sharp rectangle
                      ),
                      minimumSize: Size(200, 50), // Make button slimmer
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),  // Text color to match outline
                    ),
                  ),
                  Spacer(flex: 2),  // Add space below the buttons
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}