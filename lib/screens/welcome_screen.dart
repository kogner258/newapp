import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'waitlist_signup_screen.dart';
import 'key_signup_screen.dart';
import '../widgets/carousel_widget.dart'; // Adjust import path as needed

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true;
  List<String> _albumImages = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentAlbumImages();
  }

Future<void> _fetchRecentAlbumImages() async {
  try {
    // Query 'albums' collection, sorted by 'createdAt' descending, limit to 25
    final albumsSnapshot = await FirebaseFirestore.instance
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .limit(25)
        .get();

    List<String> imageUrls = [];

    for (var albumDoc in albumsSnapshot.docs) {
      final albumData = albumDoc.data();
      if (albumData != null && albumData['coverUrl'] != null) {
        imageUrls.add(albumData['coverUrl'] as String);
      }
    }

    setState(() {
      _albumImages = imageUrls;
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching album images: $e');
    setState(() {
      _albumImages = [];
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/waitlistwelcome.png',
              fit: BoxFit.contain, // or BoxFit.cover if you'd like
            ),
          ),

          // Foreground content
          Column(
            children: [
              SizedBox(height: 80),

              // Dissonant Logo at top
              Center(
                child: Image.asset(
                  'assets/dissonantlogotext.png',
                  height: 70,
                  width: 350,
                ),
              ),
              Spacer(flex: 1),

              // Demand message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Due to high demand, account creation is currently suspended.\n'
                  'Join the waitlist and we will let you in as room opens up!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // or black if your background is light
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),

              // Large "Join Waitlist" button
              CustomRetroButton(
                text: 'Join Waitlist',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WaitlistSignUpScreen()),
                  );
                },
                width: 350,
                height: 60,
                fontSize: 22,
              ),
              Spacer(flex: 1),

              // Carousel (or loading indicator if still fetching)
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_albumImages.isEmpty)
                Text(
                  'No recent albums found.',
                  style: TextStyle(color: Colors.white),
                )
              else
                // Show the CarouselWidget
                CarouselWidget(imgList: _albumImages),

              Spacer(flex: 1),

              // Smaller "Sign Up with Key" button
              CustomRetroButton(
                text: 'Sign Up with Key',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => KeySignUpScreen()),
                  );
                },
                width: 220,
                height: 50,
                fontSize: 16,
              ),
              SizedBox(height: 16),

              // Smaller "Log In" button
              CustomRetroButton(
                text: 'Log In',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                width: 220,
                height: 50,
                fontSize: 16,
              ),

              Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reuse or adapt your existing CustomRetroButton with optional parameters
class CustomRetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double fontSize;

  const CustomRetroButton({
    required this.text,
    required this.onPressed,
    this.width = 350,
    this.height = 60,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          // Bottom shadow layer
          Container(
            width: width,
            height: height,
            margin: EdgeInsets.only(top: 4, left: 4),
            decoration: BoxDecoration(
              color: Colors.black,  // Shadow color
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Top button layer
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5), // Off-white button color
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
