import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/order_model.dart';
import '/services/firestore_service.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String _firstName = '';
  String _lastName = '';
  String _address = '';
  String _city = '';
  String _state = '';
  String _zipcode = '';
  String? _selectedAddress;

  bool _hasOrdered = false; // Local variable to store the order status
  bool _isLoading = true; // Local variable to indicate loading state

  final List<String> _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL',
    'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT',
    'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI',
    'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (!mounted) return;
        setState(() {
          _hasOrdered = userDoc['hasOrdered'] ?? false;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderModel = Provider.of<OrderModel>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: BackgroundWidget(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: _hasOrdered
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Your order has been placed!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 24, color: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Where should we send your music?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16.0),
                                  if (orderModel.previousAddresses.isNotEmpty) ...[
                                    Text(
                                      'Use a previous address:',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _selectedAddress,
                                      items: orderModel.previousAddresses
                                          .map((address) => DropdownMenuItem(
                                                value: address,
                                                child: Text(address),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAddress = value;
                                          if (value != null) {
                                            _populateFieldsFromSelectedAddress(value);
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    SizedBox(height: 16.0),
                                    Text(
                                      'Or enter a new address:',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                  SizedBox(height: 16.0),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your first name';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _firstName = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your last name';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _lastName = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Address (including apartment number)',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your address';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _address = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your city';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _city = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'State',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _state.isNotEmpty ? _state : null,
                                    items: _states.map((String state) {
                                      return DropdownMenuItem<String>(
                                        value: state,
                                        child: Text(state),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _state = newValue ?? '';
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select your state';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Zipcode',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your zipcode';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _zipcode = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.0),
                                  OutlinedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        final address = '$_firstName $_lastName\n$_address\n$_city, $_state $_zipcode';
                                        _firestoreService.addOrder(user?.uid ?? '', address).then((_) {
                                          FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                                            'hasOrdered': true,
                                          });
                                          if (!mounted) return;
                                          setState(() {
                                            _hasOrdered = true;
                                          });
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Color(0xFFFFA500)),
                                      backgroundColor: Color(0xFFFFA500), // Orange background
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero, // Square shape
                                      ),
                                    ),
                                    child: Text(
                                      'Order Your CD',
                                      style: TextStyle(color: Colors.white), // Orange text
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
      ),
    );
  }

  void _populateFieldsFromSelectedAddress(String address) {
    // Assuming the address is stored in the format 'First Last\nAddress\nCity, State Zipcode'
    List<String> parts = address.split('\n');
    if (parts.length == 3) {
      List<String> nameParts = parts[0].split(' ');
      if (nameParts.length >= 2) {
        _firstName = nameParts[0];
        _lastName = nameParts[1];
      }
      _address = parts[1];
      List<String> cityStateZip = parts[2].split(', ');
      if (cityStateZip.length == 2) {
        _city = cityStateZip[0];
        List<String> stateZip = cityStateZip[1].split(' ');
        if (stateZip.length == 2) {
          _state = stateZip[0];
          _zipcode = stateZip[1];
        }
      }
    }
    setState(() {});
  }
}