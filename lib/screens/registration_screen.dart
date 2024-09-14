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
    if (_formKey.currentState!.validate()) {  // Validation check
      setState(() {
        isLoading = true;
      });
      try {
        // Check if the username already exists in Firestore
        bool usernameExists = await _firestoreService.checkUsernameExists(username);
        if (usernameExists) {
          setState(() {
            isLoading = false;
            errorMessage = 'The username is already taken. Please choose another one.';
          });
          return; // Stop further execution if username exists
        }
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
          isLoading = false;
          // Handle different error codes
          if (e.code == 'email-already-in-use') {
            errorMessage = 'The email address is already in use by another account.';
          } else {
            errorMessage = e.message!;
          }
        });
      } catch (e) {
        setState(() {
          isLoading = false;
          errorMessage = 'An unexpected error occurred. Please try again later.';
        });
      }
    }
  }

  // Validation functions
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
      return 'Password must contain letters and numbers';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/welcome_background.png', // Path to your background image
              fit: BoxFit.cover,
            ),
          ),
          CustomScrollViewWithKeyboardPadding(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/dissonantlogotext.png', // Path to your Dissonant logo
                          height: 80, // Adjust height as needed
                        ),
                        SizedBox(height: 16.0),
                        CustomFormContainer(
                          width: 350, // Set the width to be consistent with design
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CustomTextField(
                                    labelText: "Username",
                                    textColor: Colors.black,
                                    onChanged: (value) {
                                      setState(() {
                                        username = value;
                                      });
                                    },
                                    validator: _validateUsername, // Added validation
                                  ),
                                  SizedBox(height: 4.0),
                                  CustomTextField(
                                    labelText: "Email",
                                    textColor: Colors.black,
                                    onChanged: (value) {
                                      setState(() {
                                        email = value;
                                      });
                                    },
                                    validator: _validateEmail, // Added validation
                                  ),
                                  SizedBox(height: 4.0),
                                  CustomTextField(
                                    labelText: "Password",
                                    obscureText: true,
                                    textColor: Colors.black,
                                    onChanged: (value) {
                                      setState(() {
                                        password = value;
                                      });
                                    },
                                    validator: _validatePassword, // Added validation
                                  ),
                                  SizedBox(height: 4.0),
                                  CustomTextField(
                                    labelText: "Confirm Password",
                                    obscureText: true,
                                    textColor: Colors.black,
                                    onChanged: (value) {
                                      setState(() {
                                        confirmPassword = value;
                                      });
                                    },
                                    validator: _validateConfirmPassword, // Added validation
                                  ),
                                  SizedBox(height: 12.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Country of Residence',
                                      labelStyle: TextStyle(color: Colors.black), // Label text color
                                      fillColor: Colors.white, // Background color for the dropdown field
                                      filled: true,
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black, // Black border when idle
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black, // Black border when focused
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    dropdownColor: Colors.white, // Background color of the dropdown options
                                    value: country,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'United States',
                                        child: Text('United States', style: TextStyle(color: Colors.black)), // Text color for the dropdown options
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        country = newValue!;
                                      });
                                    },
                                    style: TextStyle(color: Colors.black), // Text color inside the field
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'We currently only support users in the United States.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  SizedBox(height: 16.0),
                                  CustomRetroButton(
                                    text: 'Sign Up',
                                    onPressed: _register,
                                    color: Color(0xFFD24407), // Updated color for the Sign Up button
                                    fixedHeight: true, // Ensure the button height is constrained
                                    shadowColor: Colors.black.withOpacity(0.9), // Darker shadow for the button
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
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomScrollViewWithKeyboardPadding extends StatelessWidget {
  final Widget child;

  const CustomScrollViewWithKeyboardPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
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
  final String? Function(String?)? validator;

  const CustomTextField({
    required this.labelText,
    this.obscureText = false,
    this.onChanged,
    this.textColor = Colors.black,
    this.isFlat = false,  // Flatter input field
    this.validator,
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
              validator: validator, // Added validator
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