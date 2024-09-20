import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/order_model.dart';
import '/services/firestore_service.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget
import '../widgets/retro_button_widget.dart'; // Import the RetroButtonWidget

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

  bool _hasOrdered = false;
  bool _isLoading = true;
  bool _showPlaceOrderMessage = false;

  final List<String> _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL',
    'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT',
    'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI',
    'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMostRecentOrderStatus();
  }

  /// Fetches the most recent order based on the timestamp field
  Future<void> _fetchMostRecentOrderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true) // Sorting by timestamp
          .limit(1) // Get the most recent order
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        DocumentSnapshot orderDoc = orderSnapshot.docs.first;
        final orderData = orderDoc.data() as Map<String, dynamic>;

        if (!mounted) return;
        setState(() {
          _hasOrdered = true;

          // Get the status of the most recent order
          String status = orderData['status'] ?? '';
          if (status == 'returned') {
            _showPlaceOrderMessage = true; // Show message for 'returned' status
          } else if (status == 'returnConfirmed' || status == 'kept') {
            _showPlaceOrderMessage = false; // Show form for 'returnConfirmed' or 'kept' status
          }
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _hasOrdered = false;
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
                          ? _showPlaceOrderMessage
                              ? _buildPlaceOrderMessage()
                              : _buildOrderForm(orderModel, user)
                          : _buildOrderForm(orderModel, user),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPlaceOrderMessage() {
    return Center(
      child: Text(
        "You can place another order once we receive your last album",
        style: TextStyle(fontSize: 24, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOrderForm(OrderModel orderModel, User? user) {
    return Form(
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
          RetroButton(
            text: 'Order Your CD',
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
            color: Color(0xFFFFA500), // Orange color for the retro button
          ),
        ],
      ),
    );
  }

  void _populateFieldsFromSelectedAddress(String address) {
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