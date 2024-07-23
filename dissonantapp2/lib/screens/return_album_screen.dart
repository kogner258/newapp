import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class ReturnAlbumScreen extends StatefulWidget {
  final String orderId;

  ReturnAlbumScreen({required this.orderId});

  @override
  _ReturnAlbumScreenState createState() => _ReturnAlbumScreenState();
}

class _ReturnAlbumScreenState extends State<ReturnAlbumScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _heardBefore = 'Yes';
  String _ownAlbum = 'Yes';
  String _likedAlbum = 'Yes!';
  String _miscThoughts = '';
  String _albumCoverUrl = '';
  String _albumInfo = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetails();
  }

  Future<void> _fetchAlbumDetails() async {
    try {
      final orderDoc = await _firestoreService.getOrderById(widget.orderId);
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final albumId = orderData['details']['albumId'];
        final albumDoc = await _firestoreService.getAlbumById(albumId);
        if (albumDoc.exists) {
          final album = albumDoc.data() as Map<String, dynamic>;
          setState(() {
            _albumCoverUrl = album['coverUrl'] ?? '';
            _albumInfo = '${album['artist']} - ${album['albumName']}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _albumInfo = 'Album not found';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _albumInfo = 'Order not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _albumInfo = 'Failed to load album details';
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Collect the feedback data
      Map<String, dynamic> feedback = {
        'heardBefore': _heardBefore,
        'ownAlbum': _ownAlbum,
        'likedAlbum': _likedAlbum,
        'miscThoughts': _miscThoughts,
      };

      // Save the feedback to Firestore
      await _firestoreService.submitFeedback(widget.orderId, feedback);

      // Update the order status to 'returned'
      await _firestoreService.updateOrderStatus(widget.orderId, 'returned');

      setState(() {
        _isSubmitting = false;
      });

      // Navigate back to MyMusicScreen
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Return Album'),
      ),
      body: BackgroundWidget(
        child: _isSubmitting || _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_albumCoverUrl.isNotEmpty)
                              Image.network(
                                _albumCoverUrl,
                                height: 250,
                                width: 250,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: Text('Failed to load image'));
                                },
                              ),
                            if (_albumInfo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  _albumInfo,
                                  style: TextStyle(fontSize: 24, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            SizedBox(height: 20.0),
                            Text(
                              'Please provide your feedback on the album:',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            SizedBox(height: 16.0),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Had you heard this album before?',
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              value: _heardBefore,
                              items: ['Yes', 'No'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _heardBefore = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 16.0),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Do you already own this album?',
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              value: _ownAlbum,
                              items: ['Yes', 'No'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _ownAlbum = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 16.0),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Did you like this album?',
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              value: _likedAlbum,
                              items: ['Yes!', 'Meh', 'Nah'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _likedAlbum = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Any other thoughts?',
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              maxLines: 3,
                              onChanged: (value) {
                                setState(() {
                                  _miscThoughts = value;
                                });
                              },
                            ),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFA500), // Orange background
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero, // Square shape
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              child: Text(
                                'Submit Feedback',
                                style: TextStyle(color: Colors.white), // White text
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}