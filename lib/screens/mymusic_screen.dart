import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '/services/firestore_service.dart';
import 'payment_screen.dart';
import 'return_album_screen.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/spoiler_widget.dart';
import '../widgets/retro_button_widget.dart'; // Import the RetroButtonWidget

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
  bool _isDragging = false; // Track if the user is dragging
  double _rotationAngle = 0.0; // Track rotation based on drag distance
  double _cdOpacity = 0.0; // Track opacity based on drag distance

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
    if (mounted) {
      setState(() {
        _currentImage = imageUrl;
        _albumInfo = albumInfo;
        _isAlbumRevealed = true;
        _isDragging = false; // Stop dragging when album is revealed
        _rotationAngle = 0.0; // Reset rotation
        _cdOpacity = 1.0; // Ensure full opacity when the album is revealed
      });
    }
  }

  void _resetImageAndInfo() {
    setState(() {
      _currentImage = 'assets/blank_cd.png';
      _albumInfo = '';
      _isAlbumRevealed = false;
      _isDragging = false; // Ensure dragging is reset
      _rotationAngle = 0.0; // Reset rotation
      _cdOpacity = 0.0; // Reset opacity
    });
  }

  void _startDragging() {
    setState(() {
      _isDragging = true;
    });
  }

  void _stopDragging() {
    setState(() {
      _isDragging = false;
    });
  }

  void _updateRotation(double delta) {
    setState(() {
      _rotationAngle += delta / -100.0; // Adjust this value to control spin speed
      _cdOpacity = (_rotationAngle / math.pi).clamp(0.0, 1.0); // Update opacity based on rotation
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
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isAlbumRevealed) // Display this text only after the album is revealed
                      Text(
                        "The first spin is better on physical",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 45.0),
                    if (_hasOrdered) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!_isAlbumRevealed) // Only show the blank CD if the album is not revealed
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 300, maxWidth: 300),
                              child: Image.asset(
                                'assets/blank_cd.png', // Background CD case image
                              ),
                            ),
                          if (_isDragging || !_isAlbumRevealed) // Show spinning CD while dragging or before album is revealed
                            Opacity(
                              opacity: _cdOpacity, // Control opacity based on swipe progress
                              child: Transform.rotate(
                                angle: _rotationAngle * math.pi * 2.0,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 300, maxWidth: 300),
                                  child: Image.asset(
                                    'assets/blank_cd_disc.png', // Replace with your spinning blank CD image
                                  ),
                                ),
                              ),
                            ),
                          if (_isAlbumRevealed)
                            GestureDetector(
                              onTap: () {
                                // Add your tap functionality here if necessary
                              },
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 300, maxWidth: 300),
                                    child: Image.network(
                                      _currentImage,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset('assets/blank_cd.png');
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10.0),
                                  Text(
                                    "Tap to find out more",
                                    style: TextStyle(fontSize: 16, color: Colors.blue),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_orderSent && !_isAlbumRevealed) ...[
                        SizedBox(height: 16.0),
                        Text(
                          'Your album is on its way!',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
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
              if (!_isAlbumRevealed) // Keep swipe-up indicator visible and functional
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SwipeSpoilerWidget(
                      order: _order!,
                      updateImageAndInfo: _updateImageAndInfo,
                      startDragging: _startDragging, // Start spinning CD when dragging starts
                      stopDragging: _stopDragging,   // Stop spinning CD when dragging ends
                      updateRotation: _updateRotation, // Update rotation as the user drags
                    ),
                  ),
                ),
              if (_isAlbumRevealed) // Only reveal buttons after the album is shown
                Padding(
                  padding: const EdgeInsets.only(bottom: 90.0), // Move buttons slightly up
                  child: Column(
                    children: [
                      Text(
                        "Give it a listen and make your decision",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RetroButton(
                              text: 'Return Album',
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
                              color: Color(0xFFFFA500), // Orange color for Return Album
                            ),
                          ),
                          SizedBox(width: 20.0),
                          Expanded(
                            child: RetroButton(
                              text: 'Keep Album',
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PaymentScreen(orderId: _order!.id)),
                                );
                                if (result == true) {
                                  _resetImageAndInfo();
                                }
                              },
                              color: Colors.orange, // Orange color for Keep Album
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}