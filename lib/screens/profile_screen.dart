import 'package:dissonantapp2/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'admin_dashboard_screen.dart';
import 'taste_profile_screen.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget
import '../widgets/stats_bar_widget.dart'; // Import the StatsBar widget
import '../widgets/profile_picture_selector_widget.dart'; // Import the ProfilePictureSelector
import '../widgets/retro_button_widget.dart'; // Import the RetroButtonWidget
import '../widgets/retro_form_container_widget.dart'; // Import the RetroFormContainerWidget

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
  String? _userName;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _checkAdminStatus();
    _fetchUserStats();
    _fetchUserName();
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

  Future<void> _fetchUserName() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      setState(() {
        _userName = userDoc['username'];
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
                'Welcome, ${_userName ?? 'User'}',
                style: TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ProfilePictureSelector(), // Keep the Profile Picture Selector as is
              SizedBox(height: 20),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                RetroFormContainerWidget(
                  width: double.infinity,
                  child: StatsBar(albumsSentBack: _albumsSentBack, albumsKept: _albumsKept),
                ), // Wrap StatsBar in RetroFormContainerWidget for consistent styling
              SizedBox(height: 20),
              RetroButton(
                text: 'Edit Taste Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TasteProfileScreen()),
                  );
                },
                color: Color(0xFFFFA500), // Orange color for the button
                fixedHeight: true,
              ),
              if (_isAdmin) ...[
                SizedBox(height: 20),
                RetroButton(
                  text: 'Admin Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                    );
                  },
                  color: Color(0xFFFFA500), // Orange color for the button
                  fixedHeight: true,
                ),
              ],
              Spacer(),
              RetroButton(
                text: 'Logout',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomeScreen()),
                  );
                },
                color: Colors.red, // Red color for the button
                fixedHeight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}