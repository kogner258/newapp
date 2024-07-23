import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes.dart';
import '/services/firestore_service.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late String username;
  late String email;
  late String password;
  late String confirmPassword;
  String country = 'United States';
  bool isLoading = false;
  String errorMessage = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          await user.updateDisplayName(username);
          await user.sendEmailVerification();

          await _firestoreService.addUser(user.uid, username, email, country);

          Navigator.pushReplacementNamed(context, emailVerificationRoute);
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message!;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: BackgroundWidget(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Add the logo above the registration fields
                      Image.asset(
                        'assets/dissonantlogo.png', // Update with your logo's path
                        height: 100, // Adjust the height as needed
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            username = value;
                          });
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            email = value;
                          });
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            password = value;
                          });
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Confirm Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != password) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            confirmPassword = value;
                          });
                        },
                      ),
                      SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Country of Residence',
                          border: OutlineInputBorder(),
                        ),
                        value: country,
                        items: [
                          DropdownMenuItem(
                            value: 'United States',
                            child: Text('United States'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            country = newValue!;
                          });
                        },
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'We currently only support users in the United States.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFA500), // Orange background
                          foregroundColor: Colors.white, // White text
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero, // Square shape
                          ),
                          minimumSize: Size(200, 50), // Make button size appropriate
                        ),
                        child: Text('Sign Up'),
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}