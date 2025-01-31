// lib/screens/followers_list_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/windows95_window.dart';
import '../widgets/grainy_background_widget.dart';
import 'personal_profile_screen.dart'; // Import the new PersonalProfileScreen

class FollowersListScreen extends StatefulWidget {
  final List<String> followers;

  const FollowersListScreen({Key? key, required this.followers}) : super(key: key);

  @override
  _FollowersListScreenState createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _followerProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowerProfiles();
  }

  /// Fetches profiles of all followers.
  void _fetchFollowerProfiles() async {
    try {
      List<Map<String, dynamic>> profiles = [];

      for (String followerId in widget.followers) {
        Map<String, dynamic>? profile =
            await _firestoreService.getUserPublicProfile(followerId);
        if (profile != null) {
          profiles.add({
            'userId': followerId,
            'username': profile['username'] ?? 'Unknown User',
            'profilePictureUrl': profile['profilePictureUrl'],
            'bannerUrl': profile['bannerUrl'],
          });
        }
      }

      setState(() {
        _followerProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching follower profiles: $e');
      setState(() {
        _isLoading = false;
      });
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load followers.',
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
        title: Text('Followers'),
        backgroundColor: Colors.blueGrey,
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Windows95Window(
            showTitleBar: false,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _followerProfiles.isEmpty
                    ? Center(
                        child: Text(
                          'No followers yet.',
                          style: TextStyle(fontFamily: 'MS Sans Serif'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _followerProfiles.length,
                        itemBuilder: (context, index) {
                          final follower = _followerProfiles[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: follower['profilePictureUrl'] != null
                                  ? NetworkImage(follower['profilePictureUrl'])
                                  : null,
                              backgroundColor: Colors.grey[400],
                              child: follower['profilePictureUrl'] == null
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              follower['username'],
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
                                      PersonalProfileScreen(userId: follower['userId']),
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
