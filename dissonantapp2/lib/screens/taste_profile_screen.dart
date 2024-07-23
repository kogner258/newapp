import 'package:dissonantapp2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; // Make sure to import MyHomePage

class TasteProfileScreen extends StatefulWidget {
  @override
  _TasteProfileScreenState createState() => _TasteProfileScreenState();
}

class _TasteProfileScreenState extends State<TasteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  List<String> _selectedGenres = [];
  String _albumsListened = '';

  final List<String> _genres = [
    'Rock', 'Pop', 'Jazz', 'Classical', 'Hip-hop', 'Country', 'Electronic', 'Metal', 'Folk', 'Experimental', 'Alternative', 'R&B'
  ];

  final List<String> _albumsListenedOptions = [
    'Music Enjoyer (0-200)', 'Music Lover (200-1000)', 'Music Lover (1000-4000)', 'Music Uncle (4000+)'
  ];

  void _submitTasteProfile(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'tasteProfile': {
        'genres': _selectedGenres,
        'albumsListened': _albumsListened,
      },
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MyHomePage()), 
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Taste Profile Survey'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Select your favorite music genres:',
                style: TextStyle(fontSize: 18),
              ),
              ..._genres.map((genre) {
                return CheckboxListTile(
                  title: Text(genre),
                  value: _selectedGenres.contains(genre),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
              SizedBox(height: 16.0),
              Text(
                'About how many albums have you listened to?',
                style: TextStyle(fontSize: 18),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: _albumsListened.isNotEmpty ? _albumsListened : null,
                items: _albumsListenedOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _albumsListened = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an option';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _submitTasteProfile(user?.uid ?? '');
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}