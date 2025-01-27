// lib/screens/following_list_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/windows95_window.dart';
import '../widgets/grainy_background_widget.dart';
import 'personal_profile_screen.dart'; // Import the new PersonalProfileScreen

class FollowingListScreen extends StatefulWidget {
  final List<String> following;

  const FollowingListScreen({Key? key, required this.following}) : super(key: key);

  @override
  _FollowingListScreenState createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _followingProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowingProfiles();
  }

  /// Fetches profiles of all followed users.
  void _fetchFollowingProfiles() async {
    try {
      List<Map<String, dynamic>> profiles = [];

      for (String followingId in widget.following) {
        Map<String, dynamic>? profile =
            await _firestoreService.getUserPublicProfile(followingId);
        if (profile != null) {
          profiles.add({
            'userId': followingId,
            'username': profile['username'] ?? 'Unknown User',
            'profilePictureUrl': profile['profilePictureUrl'],
            'bannerUrl': profile['bannerUrl'],
          });
        }
      }

      setState(() {
        _followingProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching following profiles: $e');
      setState(() {
        _isLoading = false;
      });
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load following users.',
            style: TextStyle(fontFamily: 'MS Sans Serif'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Following'),
        backgroundColor: Colors.blueGrey,
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Windows95Window(
            showTitleBar: false,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _followingProfiles.isEmpty
                    ? Center(
                        child: Text(
                          'Not following anyone yet.',
                          style: TextStyle(fontFamily: 'MS Sans Serif'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _followingProfiles.length,
                        itemBuilder: (context, index) {
                          final followedUser = _followingProfiles[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: followedUser['profilePictureUrl'] != null
                                  ? NetworkImage(followedUser['profilePictureUrl'])
                                  : null,
                              backgroundColor: Colors.grey[400],
                              child: followedUser['profilePictureUrl'] == null
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              followedUser['username'],
                              style: TextStyle(
                                fontFamily: 'MS Sans Serif',
                              ),
                            ),
                            onTap: () {
                              // Navigate to the PersonalProfileScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PersonalProfileScreen(userId: followedUser['userId']),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
