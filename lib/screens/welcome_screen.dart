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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 1),  // Add more space at the top
              // Logo at the top
              Center(
                child: Image.asset(
                  'assets/dissonantlogotext.png',  // Path to your logo image
                  height: 70,  // Adjust logo size if needed
                ),
              ),
              SizedBox(height: 16.0),  // Space between logo and text
              Spacer(flex: 2),  // Add flexible space between the logo/text and buttons
              CustomRetroButton(
                text: 'Sign up',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationScreen()),
                  );
                },
              ),
              SizedBox(height: 16.0),  // Add some space between the buttons
              CustomRetroButton(
                text: 'Log in',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              Spacer(flex: 3),  // Add more space below the buttons to center them vertically
            ],
          ),
        ],
      ),
    );
  }
}

class CustomRetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomRetroButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          // Bottom shadow layer
          Container(
            width: 350,  // Button width
            height: 60,  // Button height
            margin: EdgeInsets.only(top: 4, left: 4),  // Offset to create the shadow
            decoration: BoxDecoration(
              color: Colors.black,  // Shadow color
              borderRadius: BorderRadius.circular(4),  // Rounded corners
            ),
          ),
          // Top button layer
          Container(
            width: 350,  // Button width
            height: 60,  // Button height
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),  // Off-white button color
              border: Border.all(color: Colors.black, width: 2),  // Black border
              borderRadius: BorderRadius.circular(4),  // Rounded corners
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black,  // Text color
                fontSize: 22,  // Font size
                fontWeight: FontWeight.bold,  // Bold text
              ),
            ),
          ),
        ],
      ),
    );
  }
}