import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/services/firestore_service.dart';
import '/services/payment_service.dart';
import '../widgets/grainy_background_widget.dart'; // Import the BackgroundWidget

class PaymentScreen extends StatefulWidget {
  final String orderId;

  PaymentScreen({required this.orderId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  String? _errorMessage; // Change to nullable String

  // For album info
  String _albumCoverUrl = '';
  String _albumInfo = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetails();
  }

  Future<void> _fetchAlbumDetails() async {
    try {
      final orderDoc = await _firestoreService.getOrderById(widget.orderId);
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final albumId = orderData['details']['albumId'];
        final albumDoc = await _firestoreService.getAlbumById(albumId);
        if (albumDoc.exists) {
          final album = albumDoc.data() as Map<String, dynamic>;
          setState(() {
            _albumCoverUrl = album['coverUrl'] ?? '';
            _albumInfo = '${album['artist']} - ${album['albumName']}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Album not found';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Order not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load album details: $e';
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Create PaymentIntent on the server
      final paymentIntentData = await _paymentService.createPaymentIntent(899);

      // 2. Initialize the payment sheet
      await _paymentService.initPaymentSheet(paymentIntentData['clientSecret']);

      // 3. Display the payment sheet
      await _paymentService.presentPaymentSheet();

      // 4. Handle payment success
      await _firestoreService.updateOrderStatus(widget.orderId, 'kept');

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful. Enjoy your new album!')),
      );

      Navigator.pop(context, true);
    } on StripeException catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment canceled.')),
        );
        Navigator.pop(context, false);
      } else {
        setState(() {
          _errorMessage = e.error.localizedMessage ?? 'Payment failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $_errorMessage')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $_errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keep Your Album'),
      ),
      body: BackgroundWidget(
        child: _isProcessing || _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0, bottom: 30.0, left: 16.0, right: 16.0), // Adjusted padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Album cover and info
                      if (_albumCoverUrl.isNotEmpty)
                        Image.network(
                          _albumCoverUrl,
                          height: 300,
                          width: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(child: Text('Failed to load image'));
                          },
                        ),
                      if (_albumInfo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _albumInfo,
                            style: TextStyle(fontSize: 24, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\$8.99',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24, // Slightly bigger text
                            ),
                          ),
                          SizedBox(width: 20.0),
                          ElevatedButton(
                            onPressed: _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFA500), // Orange background
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero, // Square shape
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                            ),
                            child: Text(
                              'Purchase',
                              style: TextStyle(color: Colors.white, fontSize: 16), // White text
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        'Need a freebie?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      ),
                      Text(
                        'Reach us at dissonant@gmail.com',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Love the album but prefer vinyl?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      ),
                      Text(
                        'Our job is done. Return your CD and run to your local record store and grab it on vinyl!',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage!,
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