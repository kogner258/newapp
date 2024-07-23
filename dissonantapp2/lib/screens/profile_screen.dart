import 'package:dissonantapp2/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'taste_profile_screen.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget
import '../widgets/stats_bar_widget.dart'; // Import the StatsBar widget
import '../widgets/profile_picture_selector_widget.dart'; // Import the ProfilePictureSelector

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  bool _isAdmin = false;
  int _albumsSentBack = 0;
  int _albumsKept = 0;
  bool _isLoading = true;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _checkAdminStatus();
    _fetchUserStats();
    _fetchFirstName();
  }

  Future<void> _checkAdminStatus() async {
    if (_user != null) {
      bool isAdmin = await _firestoreService.isAdmin(_user!.uid);
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _fetchUserStats() async {
    if (_user != null) {
      final stats = await _firestoreService.getUserAlbumStats(_user!.uid);
      setState(() {
        _albumsSentBack = stats['albumsSentBack'] ?? 0;
        _albumsKept = stats['albumsKept'] ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFirstName() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      setState(() {
        _firstName = userDoc['firstName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                'Welcome, ${_firstName ?? 'User'}',
                style: TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ProfilePictureSelector(),
              SizedBox(height: 20),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                StatsBar(albumsSentBack: _albumsSentBack, albumsKept: _albumsKept),
              SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TasteProfileScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFFFA500)), // Orange outline
                  backgroundColor: Color(0xFFFFA500), // Orange background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Square shape
                  ),
                ),
                child: Text(
                  'Edit Taste Profile',
                  style: TextStyle(color: Colors.white), // Orange text
                ),
              ),
              if (_isAdmin) ...[
                SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFFFFA500)),
                    backgroundColor: Color(0xFFFFA500), // Orange background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Square shape
                    ),
                  ),
                  child: Text(
                    'Admin Dashboard',
                    style: TextStyle(color: Colors.white), // Orange text
                  ),
                ),
              ],
              Spacer(),
              OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomeScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red), // Red outline
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Square shape
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red), // Red text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}