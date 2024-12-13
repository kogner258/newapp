// lib/screens/album_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';

import '../models/album.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/dialog/genre_selection_dialog.dart';
import '../widgets/dialog/review_dialog.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/windows95_window.dart';
import '../widgets/retro_button_widget.dart';
import '../widgets/album_image_widget.dart';
import '../services/firestore_service.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailsScreen({
    Key? key,
    required this.album,
  }) : super(key: key);

  @override
  _AlbumDetailsScreenState createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;
  bool _isLoadingGenres = true;
  bool _hasVoted = false;
  bool _hasUserReview = false;
  String? _userReviewDocId;
  Map<String, int> _genreVotes = {};

  Set<String> expandedReviews = {}; // Track which reviews are expanded

  // Add a cache for usernames
  Map<String, String> _usernamesCache = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _fetchGenreData();
    _checkUserReview();
    // Evict the image from cache to ensure fresh loading
    CachedNetworkImage.evictFromCache(widget.album.albumImageUrl);
  }

  /// Utility function to check if the image format is supported.
  bool isSupportedImageFormat(String url) {
    try {
      Uri uri = Uri.parse(url);
      String extension = path.extension(uri.path).toLowerCase(); // e.g., '.png'
      print('Parsed extension: $extension for URL: $url'); // Debug log
      return (extension == '.jpg' || extension == '.jpeg' || extension == '.png');
    } catch (e) {
      print('Error parsing image URL: $url, error: $e');
      return false;
    }
  }

  Future<void> _fetchGenreData() async {
    final albumRef = FirebaseFirestore.instance
        .collection('albums')
        .doc(widget.album.albumId);

    DocumentSnapshot albumDoc = await albumRef.get();

    if (albumDoc.exists) {
      Map<String, dynamic>? data = albumDoc.data() as Map<String, dynamic>?;
      Map<String, dynamic> votesMap = data?['genreVotes'] ?? {};
      _genreVotes = votesMap.map((key, value) => MapEntry(key, value as int));

      if (_currentUserId != null) {
        String? userGenreVote =
            await _firestoreService.getUserGenreVote(widget.album.albumId, _currentUserId!);
        if (userGenreVote != null) {
          _hasVoted = true;
        } else {
          _hasVoted = false;
        }
      }
    } else {
      // Album document does not exist
      _genreVotes = {};
      _hasVoted = false;
    }

    setState(() {
      _isLoadingGenres = false;
    });
  }

  Future<void> _checkUserReview() async {
    if (_currentUserId == null) return;
    final reviewsQuery = await FirebaseFirestore.instance
        .collection('albums')
        .doc(widget.album.albumId)
        .collection('reviews')
        .where('userId', isEqualTo: _currentUserId)
        .limit(1)
        .get();
    if (reviewsQuery.docs.isNotEmpty) {
      _hasUserReview = true;
      _userReviewDocId = reviewsQuery.docs.first.id;
    } else {
      _hasUserReview = false;
      _userReviewDocId = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _showGenreSelectionDialog({String? currentGenre}) async {
    final chosenGenre = await showDialog<String>(
      context: context,
      builder: (context) => GenreSelectionDialog(currentGenre: currentGenre),
    );

    if (chosenGenre != null && chosenGenre.isNotEmpty) {
      if (_hasVoted && currentGenre != null) {
        // User wants to change their existing vote
        try {
          await _firestoreService.changeGenreVote(
            albumId: widget.album.albumId,
            userId: _currentUserId!,
            newGenre: chosenGenre,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Genre vote updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating genre vote: $e')),
          );
        }
      } else {
        // User is casting a new vote
        try {
          await _firestoreService.castGenreVote(
            albumId: widget.album.albumId,
            userId: _currentUserId!,
            chosenGenre: chosenGenre,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Genre vote cast successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error casting genre vote: $e')),
          );
        }
      }

      // Refresh UI
      await _fetchGenreData();
    }
  }

  Future<void> _showReviewDialog({String initialComment = ''}) async {
    final newComment = await showDialog<String>(
      context: context,
      builder: (context) => ReviewDialog(initialComment: initialComment),
    );

    if (newComment != null) {
      if (_currentUserId == null) return;
      if (_hasUserReview && _userReviewDocId != null) {
        // Update review
        try {
          await _firestoreService.updateReview(
            albumId: widget.album.albumId,
            reviewId: _userReviewDocId!,
            comment: newComment.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Review updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating review: $e')),
          );
        }
      } else {
        // Add new review
        try {
          final orders = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: _currentUserId)
              .where('details.albumId', isEqualTo: widget.album.albumId)
              .limit(1)
              .get();

          String orderId = orders.docs.isNotEmpty ? orders.docs.first.id : 'no_order';

          await _firestoreService.addReview(
            albumId: widget.album.albumId,
            userId: _currentUserId!,
            orderId: orderId,
            comment: newComment.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Review submitted successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting review: $e')),
          );
        }
      }

      await _checkUserReview();
      setState(() {}); // Rebuild to reflect changes
    }
  }

  Widget _buildGenresSection() {
    if (_isLoadingGenres) {
      return Center(child: CircularProgressIndicator());
    }

    // Filter out genres with 0 votes
    final filteredGenres = _genreVotes.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, int>> topGenres = filteredGenres.take(2).toList();

    List<Widget> children = [];

    if (topGenres.isEmpty) {
      children.add(_buildPlusButton());
    } else if (topGenres.length == 1) {
      children.add(_buildGenreChip(topGenres[0].key));
      children.add(SizedBox(height: 8.0));
      children.add(_buildPlusButton());
    } else {
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGenreChip(topGenres[0].key),
            SizedBox(width: 8),
            _buildGenreChip(topGenres[1].key),
          ],
        ),
      );
      children.add(SizedBox(height: 8.0));
      children.add(_buildPlusButton());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFC0C0C0),
        border: Border.all(color: Colors.black),
        boxShadow: [
          // Depth shadow to mimic Windows95 depth effect
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        genre,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPlusButton() {
    return Container(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: _hasVoted
            ? () async {
                // Fetch current genre to pass to the dialog
                String? currentGenre = await _firestoreService.getUserGenreVote(widget.album.albumId, _currentUserId!);
                _showGenreSelectionDialog(currentGenre: currentGenre);
              }
            : _showGenreSelectionDialog,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFFC0C0C0),
            border: Border.all(color: Colors.black),
            boxShadow: [
              // Add Windows95 shadow
              BoxShadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _hasVoted ? 'E' : '+', // Toggle between '+' and 'E' based on vote status
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('albums')
          .doc(widget.album.albumId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: TextStyle(color: Colors.red),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!.exists) {
          return Text(
            'Album not found.',
            style: TextStyle(color: Colors.red),
          );
        }

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        Map<String, dynamic> genreVotes = {};
        if (data.containsKey('genreVotes')) {
          genreVotes = Map<String, dynamic>.from(data['genreVotes']);
        }

        // Calculate 'Kept' and 'Returned' counts
        // Assuming 'orders' collection is separate and not part of 'genreVotes'
        // Hence, maintaining separate counts from orders

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('albumId', isEqualTo: widget.album.albumId)
              .where('status', whereIn: ['kept', 'returnedConfirmed'])
              .snapshots(),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.hasError) {
              return Text(
                'Error: ${orderSnapshot.error}',
                style: TextStyle(color: Colors.red),
              );
            }

            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            int keptCount = 0;
            int returnedCount = 0;

            for (var doc in orderSnapshot.data!.docs) {
              String status = doc['status'];
              if (status == 'kept') {
                keptCount++;
              } else if (status == 'returnedConfirmed') {
                returnedCount++;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCounterBox('Kept:', keptCount),
                SizedBox(height: 8.0),
                _buildCounterBox('Returned:', returnedCount),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCounterBox(String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFC0C0C0),
        border: Border.all(color: Colors.black),
        boxShadow: [
          // Add Windows95 shadow
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'MS Sans Serif',
            ),
          ),
          SizedBox(width: 8.0),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'MS Sans Serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewActionButton() {
    return GestureDetector(
      onTap: () {
        _showReviewDialog(
          initialComment: _hasUserReview && _userReviewDocId != null ? '...' : '',
        );
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(0xFFC0C0C0),
          border: Border.all(color: Colors.black),
          boxShadow: [
            // Add Windows95 shadow
            BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _hasUserReview ? 'E' : '+', // Toggle between '+' and 'E' based on review status
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('albums')
          .doc(widget.album.albumId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reviews.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No reviews yet.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String comment = data['comment'] ?? '';
              Timestamp? ts = data['timestamp'];
              DateTime? dt = ts?.toDate();
              String dateStr = dt != null ? DateFormat('MMM dd, yyyy').format(dt) : '';

              String userId = data['userId'];
              String orderId = data['orderId'] ?? 'no_order';

              bool expanded = expandedReviews.contains(doc.id);
              bool needsMore = comment.length > 120 && !expanded;
              String displayComment = expanded || !needsMore ? comment : (comment.substring(0, 120) + '...');

              return FutureBuilder<Map<String, String>>(
                future: _fetchUserAndStatusForReview(userId, orderId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Loading user info...',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  if (userSnapshot.hasError || userSnapshot.data == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Error loading user info',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  String username = userSnapshot.data!['username'] ?? 'Unknown User';
                  String statusNote = userSnapshot.data!['statusNote'] ?? '(hasn\'t received this album)';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
                      children: [
                        // Username
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // Status Note
                        Text(
                          statusNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        // Date
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Comment with optional 'more'
                        Text(
                          displayComment,
                          style: TextStyle(color: Colors.black),
                          maxLines: expanded ? null : 2,
                          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          textAlign: TextAlign.left, // Ensure left alignment
                        ),
                        if (needsMore)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                expandedReviews.add(doc.id);
                              });
                            },
                            child: Text(
                              'more',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _fetchUserAndStatusForReview(String userId, String orderId) async {
    Map<String, String> result = {};
    
    // Check if username is already in cache
    String username;
    if (_usernamesCache.containsKey(userId)) {
      username = _usernamesCache[userId]!;
    } else {
      // Fetch username from public profile
      final userProfile = await _firestoreService.getUserPublicProfile(userId);
      username = userProfile?['username'] ?? 'Unknown User';
      // Add to cache
      _usernamesCache[userId] = username;
    }
    
    // Determine status note based on orderId
    String statusNote = '(hasn\'t received this album)';
    if (orderId != 'no_order') {
      final orderDoc = await _firestoreService.getOrderById(orderId);
      if (orderDoc != null && orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        String status = orderData['status'] ?? 'unknown';
        if (status == 'kept') {
          statusNote = '(kept this album)';
        } else if (status == 'returnedConfirmed') {
          statusNote = '(returned this album)';
        }
      }
    }
    
    result['username'] = username;
    result['statusNote'] = statusNote;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'DISSONANT'),
      body: BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              // Top window containing album cover and details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Windows95Window(
                  showTitleBar: true, // Show the title bar for main album details
                  title: 'Album Details', // Title for the main window
                  contentBackgroundColor: Color(0xFFC0C0C0), // Grey background
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album Cover Window without Title Bar
                      Expanded(
                        flex: 1,
                        child: Windows95Window(
                          showTitleBar: false, // No title bar for album cover
                          contentPadding: EdgeInsets.zero,
                          contentBackgroundColor: Color(0xFFC0C0C0), // Grey background to match
                          child: CustomAlbumImage(
                            imageUrl: widget.album.albumImageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Album Details (Artist, Album Name, Release Year)
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLabelValue('Artist:', widget.album.artist),
                              SizedBox(height: 10),
                              _buildLabelValue('Album:', widget.album.albumName),
                              SizedBox(height: 10),
                              _buildLabelValue('Release Year:', widget.album.releaseYear),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Genres and Counter sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Genres Window
                      Expanded(
                        child: Windows95Window(
                          showTitleBar: true,
                          title: 'Genres',
                          contentBackgroundColor: Color(0xFFC0C0C0), // Grey background
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildGenresSection(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Counter Window
                      Expanded(
                        child: Windows95Window(
                          showTitleBar: true,
                          title: 'Counter',
                          contentBackgroundColor: Color(0xFFC0C0C0), // Grey background
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildCounter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // User Reviews section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Windows95Window(
                    showTitleBar: true, // Retain title bar for User Reviews
                    titleWidget: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'User Reviews',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 4),
                        _buildReviewActionButton(),
                      ],
                    ),
                    contentBackgroundColor: Color(0xFFC0C0C0), // Grey background
                    child: _buildUserReviewsSection(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
