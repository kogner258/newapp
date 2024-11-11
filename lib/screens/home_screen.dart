// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dissonantapp2/widgets/grainy_background_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/retro_button_widget.dart';
import '../widgets/bottom_navigation_widget.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import the package

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoading = true;

  PageController _pageController = PageController();
  int _currentIndex = 0;

  final double spineHeight = 45.0; // Adjusted spine height
  final int maxSpines = 3; // Maximum number of spines to display

  @override
  void initState() {
    super.initState();
    _fetchFeedItems();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (!mounted) return; // Added check
    int newIndex = _pageController.page!.round();
    if (newIndex != _currentIndex && newIndex < _feedItems.length) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  Future<void> _fetchFeedItems() async {
    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: ['kept', 'returnConfirmed'])
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> feedItems = [];

    for (var doc in ordersSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Fetch user information from the public subcollection
      DocumentSnapshot publicProfileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .collection('public')
          .doc('profile')
          .get();

      String username = 'Unknown User';

      if (publicProfileDoc.exists) {
        Map<String, dynamic>? publicData =
            publicProfileDoc.data() as Map<String, dynamic>?;
        if (publicData != null) {
          username = publicData['username'] ?? 'Unknown User';
        }
      } else {
        print('Public profile does not exist for user ID: ${data['userId']}');
      }

      // Fetch album information
      String? albumId = data['details']?['albumId'];
      if (albumId == null || albumId.isEmpty) {
        print('No albumId found in order document with ID: ${doc.id}');
        continue; // Skip this feed item or handle as needed
      }

      DocumentSnapshot albumDoc = await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .get();

      String albumName = 'Unknown Album';
      String albumImageUrl = '';

      if (albumDoc.exists) {
        Map<String, dynamic>? albumData =
            albumDoc.data() as Map<String, dynamic>?;
        if (albumData != null) {
          albumName = albumData['albumName'] ?? 'Unknown Album';
          albumImageUrl = albumData['coverUrl'] ?? '';
        }
      } else {
        print('Album document does not exist for ID: $albumId');
      }

      feedItems.add({
        'username': username,
        'status': data['status'],
        'albumName': albumName,
        'albumImageUrl': albumImageUrl,
        'albumId': albumId,
        'userId': data['userId'],
      });
    }

    if (!mounted) return; // Added check
    setState(() {
      _feedItems = feedItems;
      _isLoading = false;
    });
  }

  Future<void> _addToWishlist(
      String albumId, String albumName, String albumImageUrl) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _firestoreService.addToWishlist(
        userId: currentUser.uid,
        albumId: albumId,
        albumName: albumName,
        albumImageUrl: albumImageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Album added to your wishlist')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total reserved height for spines
    final double totalSpinesHeight = spineHeight * maxSpines;

    return Scaffold(
      body: BackgroundWidget(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  // Spines at the bottom, behind the main content
                  _buildSpines(totalSpinesHeight),

                  // Main content with reserved space at the bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: totalSpinesHeight),
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        final item = _feedItems[index];
                        return _buildAnimatedFeedItem(item, index);
                      },
                    ),
                  ),

                  // Title text at the top
                  Positioned(
                    top: 20.0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'My Feed',
                        style: TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),

    );
  }

  Widget _buildAnimatedFeedItem(Map<String, dynamic> item, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double opacity = 1.0;
        if (_pageController.position.haveDimensions) {
          double page =
              _pageController.page ?? _pageController.initialPage.toDouble();
          double difference = (index - page).abs();
          opacity = (1 - difference).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: opacity,
          child: _buildFeedItem(item),
        );
      },
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    String actionText = item['status'] == 'kept' ? 'kept' : 'returned';

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding:
            EdgeInsets.only(top: 85.0), // Adjust this value to slide content down
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User action text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Username and action
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item['username']} $actionText',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(width: 10.0), // Space between texts

                  // Album name
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item['albumName']}',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),

            // Album image with spinner while loading
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: item['albumImageUrl'] != ''
                  ? CachedNetworkImage(
                      imageUrl: item['albumImageUrl'],
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error, size: 100),
                    )
                  : Icon(
                      Icons.album,
                      size: 120,
                    ),
            ),
            SizedBox(height: 30.0),

            // Add to Wishlist button
            RetroButton(
              text: 'Add to Wishlist',
              onPressed: () {
                _addToWishlist(
                  item['albumId'],
                  item['albumName'],
                  item['albumImageUrl'],
                );
              },
              color: Color(0xFFFFA500),
              fixedHeight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpines(double totalSpinesHeight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: totalSpinesHeight,
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            List<Widget> spineWidgets = [];

            double page = _pageController.hasClients && _pageController.page != null
                ? _pageController.page!
                : _currentIndex.toDouble();

            for (int i = 0; i < maxSpines; i++) {
              int spineIndex = _currentIndex + i + 1; // Corrected index
              if (spineIndex < _feedItems.length) {
                double offsetFromCurrent = page - _currentIndex;

                // Adjust bottom offset to stack spines properly
                double bottomOffset = (maxSpines - i - 1) * spineHeight +
                    offsetFromCurrent * spineHeight;

                // Adjust scaling and opacity to make spines smaller and more faded as they go down
                double scale =
                    (1.0 - i * 0.05 - offsetFromCurrent * 0.02).clamp(0.0, 1.0);
                double opacity = (1.0 - i * 0.3 - offsetFromCurrent * 0.1)
                    .clamp(0.0, 1.0); // Updated

                Widget spine = Positioned(
                  bottom: bottomOffset,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: opacity,
                      child: _buildSpine(_feedItems[spineIndex]),
                    ),
                  ),
                );

                spineWidgets.add(spine);
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: spineWidgets,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpine(Map<String, dynamic> item) {
    // Shorten album name if over 26 characters
    String albumName = item['albumName'];
    if (albumName.length > 26) {
      albumName = albumName.substring(0, 23) + '...';
    }

    return Container(
      height: spineHeight,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Spine image
          Positioned.fill(
            child: Image.asset(
              'assets/spineasset.png',
            ),
          ),
          // Album name on the white label
          Positioned(
            left: 60, // Your custom position
            top: 0,
            bottom: 0,
            right: 10, // Ensure text doesn't overflow
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                albumName,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
