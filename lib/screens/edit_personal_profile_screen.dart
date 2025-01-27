import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../services/firestore_service.dart';
import '../widgets/windows95_window.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/retro_button_widget.dart';
import '../widgets/color_picker_widget.dart'; // Make sure you have this widget
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPersonalProfileScreen extends StatefulWidget {
  @override
  _EditPersonalProfileScreenState createState() =>
      _EditPersonalProfileScreenState();
}

class _EditPersonalProfileScreenState extends State<EditPersonalProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Basic fields
  String _username = '';
  String _publicBio = ''; // new public bio
  String _musicalBio = '';
  List<String> _selectedGenres = [];
  List<String> _selectedDecades = [];
  String _albumsListened = '';

  // Customizations
  String _themeColor = '#C0C0C0';
  String _fontStyle = 'MS Sans Serif';

  // Images
  File? _profileImage;
  File? _bannerImage;

  // Options
  final List<String> _genres = [
    'Rock', 'Pop', 'Jazz', 'Classical', 'Hip-hop', 'Country',
    'Electronic', 'Metal', 'Folk', 'Experimental', 'Alternative', 'R&B'
  ];
  final List<String> _decades = ['60s', '70s', '80s', '90s', '00s', '10s', '20s'];
  final List<String> _albumsListenedOptions = [
    'Music Enjoyer (0-200)',
    'Music Lover (200-1000)',
    'Music Nerd (1000-4000)',
    'Music Fanatic (4000+)'
  ];
  final List<String> _fontOptions = [
    'MS Sans Serif', 'Courier New', 'Arial', 'Comic Sans MS'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = await _firestoreService.getUserProfile(currentUser.uid);
      if (userData != null) {
        setState(() {
          _userData = userData;
          _username = userData['username'] ?? '';
          _publicBio = userData['publicBio'] ?? '';

          final tasteProfile = userData['tasteProfile'] ?? {};
          _musicalBio = tasteProfile['musicalBio'] ?? '';
          _selectedGenres = List<String>.from(tasteProfile['genres'] ?? []);
          _selectedDecades = List<String>.from(tasteProfile['decades'] ?? []);
          _albumsListened = tasteProfile['albumsListened'] ?? '';

          final customizations = userData['customizations'] ?? {};
          _themeColor = customizations['themeColor'] ?? '#C0C0C0';
          _fontStyle = customizations['fontStyle'] ?? 'MS Sans Serif';

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _bannerImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Upload images if changed
      String? profileImageUrl;
      String? bannerImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await _firestoreService.uploadProfilePicture(
          currentUser.uid,
          _profileImage!.path,
        );
      }
      if (_bannerImage != null) {
        bannerImageUrl = await _firestoreService.uploadBannerImage(
          currentUser.uid,
          _bannerImage!.path,
        );
      }

      // Prepare tasteProfile data
      final tasteProfileData = {
        'genres': _selectedGenres,
        'decades': _selectedDecades,
        'albumsListened': _albumsListened,
        'musicalBio': _musicalBio,
      };
      await _firestoreService.updateTasteProfile(currentUser.uid, tasteProfileData);

      // Update customizations
      final customizationData = {
        'themeColor': _themeColor,
        'fontStyle': _fontStyle,
      };
      await _firestoreService.updateUserCustomizations(
        currentUser.uid,
        customizationData,
      );

      // Update publicBio & username in `users/{uid}/public/profile`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('public')
          .doc('profile')
          .update({
        'username': _username,
        'publicBio': _publicBio,
      });

      // If new images, update them in the profile doc
      if (profileImageUrl != null) {
        await _firestoreService.updateUserPublicProfilePicture(
          currentUser.uid,
          profileImageUrl,
        );
      }
      if (bannerImageUrl != null) {
        await _firestoreService.updateUserBannerPicture(
          currentUser.uid,
          bannerImageUrl,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.black))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e', style: TextStyle(color: Colors.black))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Windows95Window(
            showTitleBar: false,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  TextFormField(
                    initialValue: _username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                    onChanged: (val) => _username = val,
                  ),
                  SizedBox(height: 16),

                  // Public Bio
                  Text(
                    'Public Bio:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: _publicBio,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share a short personal bio...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (val) => _publicBio = val,
                  ),
                  SizedBox(height: 16),

                  // Profile Picture
                  Text('Profile Picture:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (_userData != null && _userData!['profilePictureUrl'] != null
                                ? NetworkImage(_userData!['profilePictureUrl'])
                                : null) as ImageProvider?,
                        backgroundColor: Colors.grey[400],
                        child: _profileImage == null &&
                                (_userData == null ||
                                    _userData!['profilePictureUrl'] == null)
                            ? Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 16),
                      RetroButton(
                        text: 'Change',
                        onPressed: () => _pickImage(true),
                        color: Color(0xFFD24407),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Banner Image
                  Text('Banner Image:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      image: _bannerImage != null
                          ? DecorationImage(
                              image: FileImage(_bannerImage!),
                              fit: BoxFit.cover,
                            )
                          : (_userData != null && _userData!['bannerUrl'] != null
                              ? DecorationImage(
                                  image: NetworkImage(_userData!['bannerUrl']),
                                  fit: BoxFit.cover,
                                )
                              : null),
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: _bannerImage == null &&
                            (_userData == null || _userData!['bannerUrl'] == null)
                        ? Center(child: Text('No Banner', style: TextStyle(color: Colors.black)))
                        : null,
                  ),
                  SizedBox(height: 8),
                  RetroButton(
                    text: 'Change Banner',
                    onPressed: () => _pickImage(false),
                    color: Color(0xFFD24407),
                  ),
                  SizedBox(height: 16),

                  // Genres
                  Text('Favorite Genres:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Wrap(
                    spacing: 8.0,
                    children: _genres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(genre, style: TextStyle(color: Colors.black)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                        selectedColor: Colors.blueGrey,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Decades
                  Text('Favorite Decades:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Wrap(
                    spacing: 8.0,
                    children: _decades.map((decade) {
                      final isSelected = _selectedDecades.contains(decade);
                      return FilterChip(
                        label: Text(decade, style: TextStyle(color: Colors.black)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDecades.add(decade);
                            } else {
                              _selectedDecades.remove(decade);
                            }
                          });
                        },
                        selectedColor: Colors.blueGrey,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Albums Listened
                  Text('Albums Listened To:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _albumsListened.isNotEmpty ? _albumsListened : null,
                    items: _albumsListenedOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (val) => _albumsListened = val ?? '',
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please select an option' : null,
                  ),
                  SizedBox(height: 16),

                  // Musical Bio
                  Text('Musical Bio:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: _musicalBio,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tell us about your music taste...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (val) => _musicalBio = val,
                  ),
                  SizedBox(height: 16),

                  // Theme Color
                  Text('Theme Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  ColorPickerWidget(
                    currentColor: HexColor(_themeColor),
                    onColorChanged: (color) {
                      setState(() {
                        _themeColor =
                            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Font Style
                  Text('Font Style:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _fontStyle,
                    items: _fontOptions.map((font) {
                      return DropdownMenuItem<String>(
                        value: font,
                        child: Text(font, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (val) => _fontStyle = val ?? 'MS Sans Serif',
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please select a font style' : null,
                  ),
                  SizedBox(height: 16),

                  // Save Button
                  Center(
                    child: RetroButton(
                      text: 'Save Changes',
                      onPressed: _submitProfile,
                      color: Color(0xFFD24407),
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

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    String sanitized = hexColor.toUpperCase().replaceAll('#', '');
    if (sanitized.length == 6) {
      sanitized = 'FF$sanitized';
    }
    return int.parse(sanitized, radix: 16);
  }
}
