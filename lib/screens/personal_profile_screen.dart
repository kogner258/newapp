import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../widgets/windows95_window.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/retro_button_widget.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';
import 'edit_personal_profile_screen.dart';

class PersonalProfileScreen extends StatefulWidget {
  final String userId;

  const PersonalProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _PersonalProfileScreenState createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<String> _followers = [];
  List<String> _following = [];

  // For album history
  List<Map<String, dynamic>> _keptAlbums = [];
  List<Map<String, dynamic>> _returnedAlbums = [];

  // For wishlist
  List<Map<String, dynamic>> _wishlist = [];

  // For kept vs returned ratio
  int _keptCount = 0;
  int _returnedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      // 1. Fetch public profile data
      final profileData =
          await _firestoreService.getUserPublicProfile(widget.userId);

      // 2. Fetch followers & following
      final followers = await _firestoreService.getFollowers(widget.userId);
      final following = await _firestoreService.getFollowing(widget.userId);

      // 3. Fetch album history (kept or returnedConfirmed)
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status', whereIn: ['kept', 'returnedConfirmed'])
          .get();

      final keptAlbums = <Map<String, dynamic>>[];
      final returnedAlbums = <Map<String, dynamic>>[];

      int keptCount = 0;
      int returnedCount = 0;

      for (var doc in ordersQuery.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final details = data['details'] ?? {};

        final albumId = data['albumId'] ?? details['albumId'];
        final albumName = details['albumName'] ?? '(Unknown Album)';

        if (status == 'kept') {
          keptAlbums.add({
            'albumId': albumId,
            'albumName': albumName,
          });
          keptCount++;
        } else if (status == 'returnedConfirmed') {
          returnedAlbums.add({
            'albumId': albumId,
            'albumName': albumName,
          });
          returnedCount++;
        }
      }

      // 4. Fetch wishlist
      final wishlistSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('wishlist')
          .get();
      final wishlist = wishlistSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'albumId': doc.id,
          'albumName': data['albumName'] ?? '(Unknown Album)',
          'albumImageUrl': data['albumImageUrl'] ?? null,
        };
      }).toList();

      setState(() {
        _userData = profileData;
        _followers = followers;
        _following = following;

        _keptAlbums = keptAlbums;
        _returnedAlbums = returnedAlbums;
        _keptCount = keptCount;
        _returnedCount = returnedCount;

        _wishlist = wishlist;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching profile data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile.', style: TextStyle(color: Colors.black))),
      );
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPersonalProfileScreen()),
    ).then((_) => _fetchProfileData());
  }

  void _navigateToFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListScreen(followers: _followers),
      ),
    );
  }

  void _navigateToFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingListScreen(following: _following),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: Text('Error loading profile.', style: TextStyle(color: Colors.black)),
        ),
      );
    }

    final currentUserId = _auth.currentUser?.uid;
    final isOwnProfile = (currentUserId == widget.userId);

    final username = _userData!['username'] ?? 'Unknown User';
    final profilePictureUrl = _userData!['profilePictureUrl'];
    final bannerUrl = _userData!['bannerUrl'];
    final publicBio = _userData!['publicBio'] ?? '';

    final tasteProfile = _userData!['tasteProfile'] ?? {};
    final favoriteGenres = (tasteProfile['genres'] as List?) ?? [];
    final favoriteDecades = (tasteProfile['decades'] as List?) ?? [];

    final totalAlbums = _keptCount + _returnedCount;
    double keptRatio = 0;
    double returnedRatio = 0;
    if (totalAlbums > 0) {
      keptRatio = _keptCount / totalAlbums;
      returnedRatio = _returnedCount / totalAlbums;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$username\'s Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: _navigateToEditProfile,
            ),
        ],
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Windows95Window(
            showTitleBar: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                if (bannerUrl != null && bannerUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(bannerUrl),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 80,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        'No Banner',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                SizedBox(height: 16),

                // Profile + Username
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (profilePictureUrl != null &&
                              profilePictureUrl.isNotEmpty)
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      backgroundColor: Colors.grey[400],
                      child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MS Sans Serif',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Bio
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Divider(color: Colors.black),
                        Text(
                          publicBio.isNotEmpty ? publicBio : 'No personal bio set.',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Favorites
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favorites',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Divider(color: Colors.black),
                        Text(
                          'Genres: ${favoriteGenres.isNotEmpty ? favoriteGenres.join(', ') : 'N/A'}',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Decades: ${favoriteDecades.isNotEmpty ? favoriteDecades.join(', ') : 'N/A'}',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Album History
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Album History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Divider(color: Colors.black),
                        if (_keptAlbums.isEmpty && _returnedAlbums.isEmpty)
                          Text('No history found.', style: TextStyle(color: Colors.black)),
                        if (_keptAlbums.isNotEmpty)
                          ..._keptAlbums.map(
                            (album) => Text(
                              'Kept: ${album['albumName']}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        if (_returnedAlbums.isNotEmpty)
                          ..._returnedAlbums.map(
                            (album) => Text(
                              'Returned: ${album['albumName']}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Wishlist
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wishlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Divider(color: Colors.black),
                        if (_wishlist.isEmpty)
                          Text('No wishlist items.', style: TextStyle(color: Colors.black)),
                        if (_wishlist.isNotEmpty)
                          ..._wishlist.map((item) {
                            final albumName = item['albumName'] ?? '(Unknown)';
                            return Text('- $albumName', style: TextStyle(color: Colors.black));
                          }).toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Fun Scale
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fun Scale',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Divider(color: Colors.black),
                        Text('Albums Kept: $_keptCount', style: TextStyle(color: Colors.black)),
                        Text('Albums Returned: $_returnedCount', style: TextStyle(color: Colors.black)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: (_keptCount == 0 && _returnedCount == 0)
                                  ? 1
                                  : _keptCount,
                              child: Container(
                                height: 10,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              flex: (_keptCount == 0 && _returnedCount == 0)
                                  ? 0
                                  : _returnedCount,
                              child: Container(
                                height: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Keeps More', style: TextStyle(color: Colors.black)),
                            Text('Returns More', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Followers & Following
                Windows95Window(
                  showTitleBar: false,
                  contentBackgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              _followers.length.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Followers', style: TextStyle(color: Colors.black)),
                            SizedBox(height: 4),
                            RetroButton(
                              text: 'View',
                              onPressed: _navigateToFollowers,
                              color: Color(0xFFD24407),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              _following.length.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Following', style: TextStyle(color: Colors.black)),
                            SizedBox(height: 4),
                            RetroButton(
                              text: 'View',
                              onPressed: _navigateToFollowing,
                              color: Color(0xFFD24407),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
