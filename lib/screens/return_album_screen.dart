import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/retro_button_widget.dart';
import '../widgets/windows95_window.dart';
import '../models/album.dart'; // For album info structure if needed

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
  bool _isLoading = true;

  String _heardBefore = 'Yes';
  String _ownAlbum = 'Yes';
  String _likedAlbum = 'Yes!';
  String _review = ''; // Replacing _miscThoughts with review

  String _albumCoverUrl = '';
  String _albumInfo = '';
  String? _albumId; // Store albumId for writing review

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetails();
  }

  Future<void> _fetchAlbumDetails() async {
    try {
      final orderDoc = await _firestoreService.getOrderById(widget.orderId);
      if (orderDoc!.exists) {
        final orderData = orderDoc?.data() as Map<String, dynamic>;
        final albumId = orderData['details']['albumId'] as String;
        _albumId = albumId;
        final albumDoc = await _firestoreService.getAlbumById(albumId);
        if (albumDoc.exists) {
          final album = albumDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _albumCoverUrl = album['coverUrl'] ?? '';
              _albumInfo = '${album['artist']} - ${album['albumName']}';
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _albumInfo = 'Album not found';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _albumInfo = 'Order not found';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _albumInfo = 'Failed to load album details';
        });
      }
    }
  }

  Future<void> _submitReview(String comment) async {
    if (_albumId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestoreService.addReview(
      albumId: _albumId!,
      userId: user.uid,
      orderId: widget.orderId,
      comment: comment,
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Collect feedback data
      Map<String, dynamic> feedback = {
        'heardBefore': _heardBefore,
        'ownAlbum': _ownAlbum,
        'likedAlbum': _likedAlbum,
        // no miscThoughts anymore
      };

      // Save feedback to Firestore
      await _firestoreService.submitFeedback(widget.orderId, feedback);

      // If user left a review
      if (_review.trim().isNotEmpty && _albumId != null) {
        await _submitReview(_review.trim());
      }

      // Update the order status to 'returned'
      await _firestoreService.updateOrderStatus(widget.orderId, 'returned');

      setState(() {
        _isSubmitting = false;
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Return Album'),
      body: BackgroundWidget(
        child: _isSubmitting || _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment:MainAxisAlignment.center,
                      crossAxisAlignment:CrossAxisAlignment.center,
                      children: [
                        if (_albumCoverUrl.isNotEmpty)
                          Image.network(
                            _albumCoverUrl,
                            height: 200,
                            width: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Text('Failed to load image', style:TextStyle(color:Colors.white)));
                            },
                          ),
                        if (_albumInfo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _albumInfo,
                              style: TextStyle(fontSize:24, color:Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(height:20),
                        Windows95Window(
                          showTitleBar: true, // or false, depending on desired behavior
                          title:'Return Feedback',
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key:_formKey,
                              child:Column(
                                crossAxisAlignment:CrossAxisAlignment.stretch,
                                mainAxisSize:MainAxisSize.min,
                                children:[
                                  Text(
                                    'Please let us know:',
                                    style:TextStyle(fontSize:18, color:Colors.black),
                                  ),
                                  SizedBox(height:16.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText:'Had you heard this album before?',
                                      labelStyle:TextStyle(color:Colors.black),
                                      filled:true,
                                      fillColor:Colors.white,
                                      enabledBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                      focusedBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                    ),
                                    dropdownColor:Colors.white,
                                    value:_heardBefore,
                                    items:['Yes','No'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value:value,
                                        child:Text(value, style:TextStyle(color:Colors.black)),
                                      );
                                    }).toList(),
                                    onChanged:(newValue) {
                                      setState(() {
                                        _heardBefore = newValue!;
                                      });
                                    },
                                  ),
                                  SizedBox(height:16.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText:'Do you already own this album?',
                                      labelStyle:TextStyle(color:Colors.black),
                                      filled:true,
                                      fillColor:Colors.white,
                                      enabledBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                      focusedBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                    ),
                                    dropdownColor:Colors.white,
                                    value:_ownAlbum,
                                    items:['Yes','No'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value:value,
                                        child:Text(value, style:TextStyle(color:Colors.black)),
                                      );
                                    }).toList(),
                                    onChanged:(newValue) {
                                      setState(() {
                                        _ownAlbum = newValue!;
                                      });
                                    },
                                  ),
                                  SizedBox(height:16.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText:'Did you like this album?',
                                      labelStyle:TextStyle(color:Colors.black),
                                      filled:true,
                                      fillColor:Colors.white,
                                      enabledBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                      focusedBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                    ),
                                    value:_likedAlbum,
                                    dropdownColor:Colors.white,
                                    items:['Yes!','Meh','Nah'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value:value,
                                        child:Text(value, style:TextStyle(color:Colors.black)),
                                      );
                                    }).toList(),
                                    onChanged:(newValue) {
                                      setState(() {
                                        _likedAlbum = newValue!;
                                      });
                                    },
                                  ),
                                  SizedBox(height:16.0),
                                  // Optional Leave a Review
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText:'Leave a review!',
                                      labelStyle:TextStyle(color:Colors.black),
                                      filled:true,
                                      fillColor:Colors.white,
                                      enabledBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                      focusedBorder:OutlineInputBorder(
                                        borderSide: BorderSide(color:Colors.black, width:2),
                                      ),
                                    ),
                                    style: TextStyle(color:Colors.black),
                                    maxLines:3,
                                    onChanged:(value) {
                                      _review = value;
                                    },
                                  ),
                                  SizedBox(height:16.0),
                                  RetroButton(
                                    text:'Submit Feedback',
                                    onPressed:_submitForm,
                                    color:Color(0xFFD24407),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
