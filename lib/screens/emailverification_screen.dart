// email_verification_screen.dart
import 'package:dissonantapp2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool isLoading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  void _checkEmailVerification() async {
    setState(() {
      isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    setState(() {
      isEmailVerified = user?.emailVerified ?? false;
      isLoading = false;
    });

    if (isEmailVerified) {
      // Navigate to Home Screen or desired screen
      Navigator.pushReplacementNamed(context, tasteProfileRoute);
    }
  }

  void _sendVerificationEmail() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() {
        message = 'Verification email sent. Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        message = 'Failed to send verification email. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Your Email'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'A verification email has been sent to your email address. Please verify to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16.0),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: TextStyle(
                          color: message.contains('sent')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _sendVerificationEmail,
                      child: Text('Resend Verification Email'),
                    ),
                    SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: _checkEmailVerification,
                      child: Text('I have Verified'),
                    ),
                    SizedBox(height: 8.0),
                    TextButton(
                      onPressed: _signOut,
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
