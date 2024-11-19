import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/grainy_background_widget.dart';
import '../widgets/retro_button_widget.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();

  String _state = '';
  String? _selectedAddress;
  bool _isNewAddress = true;
  bool _hasOrdered = false;
  bool _isLoading = true;
  String _mostRecentOrderStatus = '';

  List<String> _previousAddresses = [];

  final List<String> _states = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY'
  ];

  final FocusNode _zipcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchMostRecentOrderStatus();
    _loadPreviousAddresses();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipcodeFocusNode.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMostRecentOrderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        DocumentSnapshot orderDoc = orderSnapshot.docs.first;
        String status = orderDoc['status'] ?? '';

        if (!mounted) return;
        setState(() {
          _mostRecentOrderStatus = status;
          _hasOrdered = !(status == 'kept' || status == 'returnedConfirmed');
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

  Future<void> _loadPreviousAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      Set<String> addressSet =
          ordersSnapshot.docs.map((doc) => doc['address'] as String).toSet();
      List<String> addresses = addressSet.take(3).toList();

      setState(() {
        _previousAddresses = addresses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BackgroundWidget(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasOrdered
                ? _buildPlaceOrderMessage(_mostRecentOrderStatus)
                : KeyboardActions(
                    config: _buildKeyboardActionsConfig(),
                    child: SafeArea(
                      child: Form(
                        key: _formKey,
                        child: _buildOrderForm(user),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPlaceOrderMessage(String status) {
    String message;
    if (status == 'returned') {
      message = "Once we've confirmed your return you'll be able to order another album!";
    } else if (status == 'pending' || status == 'sent' || status == 'new') {
      message = "Thanks for placing an order! You will be able to place another once this one is completed.";
    } else {
      message = "You can now place a new order.";
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: TextStyle(fontSize: 24, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOrderForm(User? user) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where should we send your CD?',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.0),
          if (_previousAddresses.isNotEmpty) ...[
            Text('Use a previous address:',
                style: TextStyle(color: Colors.white)),
            DropdownButtonFormField<String>(
              value: _selectedAddress,
              items: _previousAddresses.map((address) {
                return DropdownMenuItem<String>(
                  value: address,
                  child: Text(address, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAddress = value;
                  if (value != null) {
                    _populateFieldsFromSelectedAddress(value);
                  }
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
              dropdownColor: Colors.black87,
            ),
            SizedBox(height: 16.0),
            Text('Or enter a new address:',
                style: TextStyle(color: Colors.white)),
          ],
          SizedBox(height: 16.0),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
                labelText: 'First Name', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your first name'
                : null,
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
                labelText: 'Last Name', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your last name'
                : null,
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
                labelText: 'Address (including apartment number)',
                border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your address'
                : null,
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
                labelText: 'City', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your city'
                : null,
          ),
          SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
                labelText: 'State', border: OutlineInputBorder()),
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
            validator: (value) => value == null || value.isEmpty
                ? 'Please select your state'
                : null,
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _zipcodeController,
            focusNode: _zipcodeFocusNode,
            decoration: InputDecoration(
                labelText: 'Zipcode', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your zipcode'
                : null,
          ),
          SizedBox(height: 16.0),
          RetroButton(
            text: 'Place Order',
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (_formKey.currentState?.validate() ?? false) {
                final address =
                    '${_firstNameController.text} ${_lastNameController.text}\n${_addressController.text}\n${_cityController.text}, $_state ${_zipcodeController.text}';
                _firestoreService.addOrder(user?.uid ?? '', address).then((_) {
                  if (!mounted) return;
                  setState(() {
                    _hasOrdered = true;
                    _mostRecentOrderStatus = 'pending';
                    if (!_previousAddresses.contains(address)) {
                      _previousAddresses.insert(0, address);
                      if (_previousAddresses.length > 3) {
                        _previousAddresses = _previousAddresses.sublist(0, 3);
                      }
                    }
                  });
                });
              }
            },
            color: Color(0xFFFFA500),
          ),
        ],
      ),
    );
  }

  KeyboardActionsConfig _buildKeyboardActionsConfig() {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      actions: [
        KeyboardActionsItem(
          focusNode: _zipcodeFocusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Done',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ],
        ),
      ],
    );
  }

  void _populateFieldsFromSelectedAddress(String address) {
    List<String> parts = address.split('\n');
    if (parts.length == 3) {
      List<String> nameParts = parts[0].split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        _lastNameController.text = nameParts.skip(1).join(' ');
      }
      _addressController.text = parts[1].trim();
      List<String> cityStateZip = parts[2].split(', ');
      if (cityStateZip.length == 2) {
        _cityController.text = cityStateZip[0].trim();
        List<String> stateZip = cityStateZip[1].split(' ');
        if (stateZip.length >= 2) {
          _state = stateZip[0].trim();
          _zipcodeController.text = stateZip.sublist(1).join(' ').trim();
        }
      }
    }
    setState(() {});
  }
}
