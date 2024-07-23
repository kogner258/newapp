import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firestore_service.dart';
import 'payment_screen.dart';
import 'return_album_screen.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class MyMusicScreen extends StatefulWidget {
  @override
  _MyMusicScreenState createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _hasOrdered = false;
  bool _orderSent = false;
  bool _returnConfirmed = false;
  bool _orderReturned = false;
  DocumentSnapshot? _order;
  String _currentImage = 'assets/blank_cd.png'; // Placeholder image
  String _albumInfo = ''; // Album information
  bool _isAlbumRevealed = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (orderSnapshot.docs.isNotEmpty) {
          final order = orderSnapshot.docs.first;
          final orderData = order.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _hasOrdered = true;
              _order = order;
              _orderSent = orderData['status'] == 'sent';
              _orderReturned = orderData['status'] == 'returned';
              _returnConfirmed = orderData['returnConfirmed'] ?? false;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  void _updateImageAndInfo(String imageUrl, String albumInfo) {
    setState(() {
      _currentImage = imageUrl;
      _albumInfo = albumInfo;
      _isAlbumRevealed = true;
    });
  }

  void _resetImageAndInfo() {
    setState(() {
      _currentImage = 'assets/blank_cd.png';
      _albumInfo = '';
      _isAlbumRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final orderData = _order?.data() as Map<String, dynamic>?;

    return Scaffold(
      body: BackgroundWidget(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_hasOrdered) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/blank_cd.png',
                        height: 300,
                        width: 300,
                      ),
                      if (_isAlbumRevealed)
                        Image.network(
                          _currentImage,
                          height: 300,
                          width: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/blank_cd.png', height: 300, width: 300);
                          },
                        ),
                    ],
                  ),
                  if (_albumInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _albumInfo,
                        style: TextStyle(fontSize: 24, color: Colors.white), // Increased font size
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_orderSent && !_isAlbumRevealed) ...[
                    SizedBox(height: 16.0),
                    Text(
                      'Your album is on its way!',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.0),
                    SpoilerWidget(order: _order!, updateImageAndInfo: _updateImageAndInfo),
                  ],
                  if (_orderReturned && !_returnConfirmed) ...[
                    SizedBox(height: 16.0),
                    Text(
                      'We\'ll update you when we receive the album!',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!_orderSent && !_isAlbumRevealed && !_orderReturned && !_returnConfirmed) ...[
                    SizedBox(height: 16.0),
                    Text(
                      'We will ship your album soon!',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_returnConfirmed) ...[
                    SizedBox(height: 16.0),
                    Text(
                      'Order an album to see your music show up here.',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_isAlbumRevealed) ...[
                    SizedBox(height: 32.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0), // Increased padding for buttons
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ReturnAlbumScreen(orderId: _order!.id)),
                                ).then((value) {
                                  if (value == true) {
                                    _resetImageAndInfo();
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFFFFA500), width: 3), // Thicker orange outline
                                backgroundColor: Colors.black, // White background
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero, // Square shape
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Return',
                                    style: TextStyle(color: Color(0xFFFFA500), fontSize: 18), // Orange text
                                  ),
                                  Text(
                                    'Album',
                                    style: TextStyle(color: Color(0xFFFFA500), fontSize: 18), // Orange text
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16.0), // Space between buttons
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PaymentScreen(orderId: _order!.id)),
                                );
                                if (result == true) {
                                  _resetImageAndInfo();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFA500), // Orange background
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero, // Square shape
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Keep',
                                    style: TextStyle(color: Colors.white, fontSize: 18), // White text
                                  ),
                                  Text(
                                    'Album',
                                    style: TextStyle(color: Colors.white, fontSize: 18), // White text
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  Center(
                    child: Text(
                      'Order an album to see your music show up here.',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpoilerWidget extends StatefulWidget {
  final DocumentSnapshot order;
  final Function(String, String) updateImageAndInfo;

  SpoilerWidget({required this.order, required this.updateImageAndInfo});

  @override
  _SpoilerWidgetState createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _imageUpdated = false;

  @override
  Widget build(BuildContext context) {
    final orderDetails = widget.order.data() as Map<String, dynamic>?;

    if (orderDetails == null || !orderDetails.containsKey('details') || !orderDetails['details'].containsKey('albumId')) {
      return Text('Error loading order details.', style: TextStyle(color: Colors.white));
    }

    final albumId = orderDetails['details']['albumId'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _imageUpdated = false; // Reset the image update flag when toggling
            });

            // Fetch album details and update the image and album info
            _fetchAlbumDetails(albumId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFA500), // Orange background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Square shape
            ),
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          ),
          child: Text(
            'View Album',
            style: TextStyle(color: Colors.white, fontSize: 16), // White text
          ),
        ),
      ],
    );
  }

  Future<void> _fetchAlbumDetails(String albumId) async {
    try {
      final albumDoc = await _firestoreService.getAlbumById(albumId);
      final album = albumDoc.data() as Map<String, dynamic>;

      if (!_imageUpdated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.updateImageAndInfo(
            album['coverUrl'] ?? 'assets/blank_cd.png',
            '${album['artist']} - ${album['albumName']}',
          );
          setState(() {
            _imageUpdated = true;
          });
        });
      }
    } catch (e) {
      print('Error loading album details: $e');
    }
  }
}