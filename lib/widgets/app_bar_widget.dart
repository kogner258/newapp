import 'package:flutter/material.dart';
import '../screens/how_it_works_screen.dart'; // Adjust the import path as needed

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  CustomAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false, // Left-justify the title
      title: Row(
        children: [
          Image.asset(
            'assets/dissonantlogo.png', // Path to your logo image
            height: 32, // Adjust the height as needed
          ),
          SizedBox(width: 8), // Add some space between the logo and the title
          Text(title),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Navigate to the HowItWorksPage with showExitButton: true
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HowItWorksPage(showExitButton: true),
              ),
            );
          },
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(
                color: Colors.white, // White outline color
                width: 3.0,          // Width of the outline
              ),
            ),
            padding: EdgeInsets.all(6.0), // Adjust padding as needed
            child: Text(
              '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,       // Adjust font size as needed
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
