import 'package:flutter/material.dart';
import '../widgets/retro_button_widget.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/retro_form_container_widget.dart';
import 'taste_profile_screen.dart';
import 'change_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class OptionsScreen extends StatefulWidget {
  @override
  _OptionsScreenState createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _deleteAccount() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you absolutely sure?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete Account'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Re-authenticate the user
      try {
        User? user = FirebaseAuth.instance.currentUser;

        // Prompt user to re-enter their password
        String? password = await _showPasswordPrompt();

        if (password == null) {
          // User canceled the re-authentication
          return;
        }

        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        String userId = user.uid;

        // Delete user data from Firestore
        await _firestoreService.deleteUserData(userId);

        // Delete Firebase user
        await user.delete();

        // Navigate to Welcome Screen
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      } catch (e) {
        print('Error deleting account: $e');
        // Handle error, e.g., show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  Future<String?> _showPasswordPrompt() async {
    TextEditingController _passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Re-enter Password'),
          content: TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(_passwordController.text),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added AppBar with back button
      appBar: AppBar(
        title: Text('Options'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BackgroundWidget(
        child: Center( // Center the content vertically
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // Centered Column for the buttons
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink to fit children
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20),
                      RetroButton(
                        text: 'Edit Taste Profile',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TasteProfileScreen()),
                          );
                        },
                        color: Color(0xFFFFA500),
                        fixedHeight: true,
                      ),
                      SizedBox(height: 20),
                      RetroButton(
                        text: 'Change Password',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                          );
                        },
                        color: Color(0xFFFFA500),
                        fixedHeight: true,
                      ),
                    ],
                  ),
                ),
                // Positioned Delete Account button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _deleteAccount,
                      child: Text(
                        'Delete My Account',
                        style: TextStyle(color: Colors.white), // Text color changed to white
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red color for delete button
                      ),
                    ),
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
