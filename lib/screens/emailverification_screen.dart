import 'package:dissonantapp2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            user = snapshot.data;
            if (user != null && user!.emailVerified) {
              Future.microtask(() => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MyHomePage()), 
                (Route<dynamic> route) => false,
              ));
            }
          }

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('A verification email has been sent to your email address.'),
                if (email != null)
                  Text('Email: $email'),
                ElevatedButton(
                  onPressed: () async {
                    await user?.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Verification email resent to $email'),
                    ));
                  },
                  child: Text('Resend Email'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: Text('Back to Login'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}