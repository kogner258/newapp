import 'package:dissonantapp2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/welcome_background.png',  // Path to your background image
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              children: [
                Spacer(flex: 1),  // Pushes the content down
                Image.asset(
                  'assets/dissonantlogotext.png',  // Path to your Dissonant logo
                  height: 80,  // Adjust height as needed
                ),
                Spacer(flex: 1),  // Pushes the content down
                SizedBox(height: 16.0),  // Space between logo and form
                _isLoading
                    ? CircularProgressIndicator()
                    : CustomFormContainer(
                        width: 350,  // Set the width to be consistent with design
                        child: Column(
                          mainAxisSize: MainAxisSize.min,  // Ensure the column only takes up the necessary vertical space
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    CustomTextField(
                                      labelText: "Email",
                                      textColor: Colors.black,
                                      onChanged: (value) {
                                        setState(() {
                                          _email = value;
                                        });
                                      },
                                      isFlat: true, // Flatter input field
                                    ),
                                    SizedBox(height: 12.0),
                                    CustomTextField(
                                      labelText: "Password",
                                      obscureText: true,
                                      textColor: Colors.black,
                                      onChanged: (value) {
                                        setState(() {
                                          _password = value;
                                        });
                                      },
                                      isFlat: true, // Flatter input field
                                    ),
                                    SizedBox(height: 12.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CustomCheckbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value!;
                                                });
                                              },
                                            ),
                                            SizedBox(width: 4.0),  // Space between checkbox and label
                                            Text(
                                              'Remember me',
                                              style: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                            );
                                          },
                                          child: Text('Forgot Password?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.0),
                                    CustomRetroButton(
                                      text: 'Log in',
                                      onPressed: _login,
                                      color: Color(0xFFD24407),  // Updated color for the Log in button
                                      fixedHeight: true,  // Ensure the button height is constrained
                                      shadowColor: Colors.black.withOpacity(0.9),  // Darker shadow for the button
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                Spacer(flex: 3),  // Pushes the content up
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomWindowFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFFFFA12C),  // Updated color for the top bar
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 2), // Only bottom border for the orange bar
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8.0,
            top: 8.0,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);  // Pop the current page off the stack
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),  // Black border
                  color: Color(0xFFF4F4F4),  // Off-white color matching the Figma design
                ),
                width: 20,
                height: 20,
                alignment: Alignment.center,  // Center the content both horizontally and vertically
                child: Text(
                  'X',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,  // Slightly adjust the font size
                    height: 1,  // Adjust line height to better center the text vertically
                    color: Colors.black,  // Black "X"
                  ),
                  textAlign: TextAlign.center,  // Center the text within the box
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const CustomCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: value ? Colors.orange : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: value
            ? Icon(
                Icons.check,
                size: 12,
                color: Colors.black,
              )
            : null,
      ),
    );
  }
}

class CustomFormContainer extends StatelessWidget {
  final Widget child;
  final double width;

  const CustomFormContainer({required this.child, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.only(bottom: 12.0),  // Adjusted padding to remove extra white space
      decoration: BoxDecoration(
        color: Color(0xFFF4F4F4),
        border: Border.all(color: Colors.black, width: 2),  // Uniform thin black outline
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),  // Darker shadow
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // Ensure the column only takes up the necessary vertical space
        children: [
          CustomWindowFrame(),  // Including window frame with the correct border
          child,
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Color textColor;
  final bool isFlat;

  const CustomTextField({
    required this.labelText,
    this.obscureText = false,
    this.onChanged,
    this.textColor = Colors.black,
    this.isFlat = false,  // Flatter input field
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0), // Space between label and input
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.0), // Space between label and input
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),  // Darker shadow
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextFormField(
              obscureText: obscureText,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isFlat ? 12 : 18),  // Flatter input field
              ),
              onChanged: onChanged,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool fixedHeight;
  final Color shadowColor;  // Custom shadow color

  const CustomRetroButton({
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFD24407),  // Updated color for the Log in button
    this.fixedHeight = false,  // Allow control over height adjustment
    this.shadowColor = Colors.black,  // Default shadow color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.9),  // Darker shadow color
            offset: Offset(4, 4),  // Slightly larger offset for more pronounced effect
            blurRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: fixedHeight ? 45 : 50,  // Adjust height to prevent overflow
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}