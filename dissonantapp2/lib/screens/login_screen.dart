import 'package:dissonantapp2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  String? _email;
  String? _password;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await _auth.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );
        if (_rememberMe) {
          await _storage.write(key: 'email', value: _email);
          await _storage.write(key: 'password', value: _password);
        } else {
          await _storage.delete(key: 'email');
          await _storage.delete(key: 'password');
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyHomePage()), 
          (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          case 'wrong-password':
            message = 'Wrong password provided.';
            break;
          case 'invalid-email':
            message = 'The email address is badly formatted.';
            break;
          case 'user-disabled':
            message = 'The user account has been disabled.';
            break;
          case 'too-many-requests':
            message = 'Too many requests. Try again later.';
            break;
          case 'invalid-credential':
            message = 'The supplied auth credential is incorrect, malformed, or has expired.';
            break;
          default:
            message = 'An unknown error occurred.';
        }
        setState(() {
          _errorMessage = message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again later.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add the logo above the login fields
                    Image.asset(
                      'assets/dissonantlogo.png', // Update with your logo's path
                      height: 150, // Adjust the height as needed
                    ),
                    SizedBox(height: 15.0),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _email = value;
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
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text('Remember me'),
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,  // Button background color
                              side: BorderSide(color: Colors.orange, width: 2),  // Orange outline
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,  // Sharp rectangle
                              ),
                              minimumSize: Size(200, 50), // Make button slimmer
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(color: Colors.orange),  // Text color to match outline
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              );
                            },
                            child: Text('Forgot Password?'),
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