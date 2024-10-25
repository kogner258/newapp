import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool showUnfulfilledOrders = false;

  final _albumFormKey = GlobalKey<FormState>();
  String _artist = '';
  String _albumName = '';
  String _releaseYear = '';
  String _quality = '';
  String _albumId = '';
  String _coverUrl = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              setState(() {
                showUnfulfilledOrders = !showUnfulfilledOrders;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.library_music),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumListScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
            },
            child: Text('Go to Home Page'),
          ),
          ElevatedButton(
            onPressed: () {
              _showAddAlbumDialog();
            },
            child: Text('Add New Album'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUsersWithStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final usersWithStatus = snapshot.data!;

                return ListView.builder(
                  itemCount: usersWithStatus.length,
                  itemBuilder: (context, index) {
                    final userMap = usersWithStatus[index];
                    final user = userMap['user'] as Map<String, dynamic>;
                    final userId = userMap['userId'] as String;
                    final status = userMap['status'] as String;

                    Color dotColor;
                    if (status == 'new') {
                      dotColor = Colors.green;
                    } else if (status == 'active') {
                      dotColor = Colors.yellow;
                    } else {
                      dotColor = Colors.transparent;
                    }

                    return ListTile(
                      leading: dotColor != Colors.transparent
                          ? Icon(Icons.circle, color: dotColor, size: 12)
                          : null,
                      title: Text(user['username'] ?? 'Unknown'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () {
                        _showUserDetails(userId, user);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUsersWithStatus() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> usersWithStatus = [];

    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      String status = await _determineUserStatus(userId);

      usersWithStatus.add({
        'userId': userId,
        'user': userData,
        'status': status,
      });
    }

    // Sort users based on status
    usersWithStatus.sort((a, b) {
      String statusA = a['status'];
      String statusB = b['status'];

      if (statusA == 'new' && statusB != 'new') {
        return -1;
      } else if (statusA != 'new' && statusB == 'new') {
        return 1;
      } else if (statusA == 'active' && statusB != 'active') {
        return -1;
      } else if (statusA != 'active' && statusB == 'active') {
        return 1;
      } else {
        return 0;
      }
    });

    return usersWithStatus;
  }

  Future<String> _determineUserStatus(String userId) async {
    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    bool hasNewOrder = false;
    bool hasActiveOrder = false;

    for (var orderDoc in ordersSnapshot.docs) {
      String status = orderDoc['status'] ?? '';
      if (status == 'new') {
        hasNewOrder = true;
        break; // Highest priority
      } else if (status == 'sent' || status == 'returned') {
        hasActiveOrder = true;
      }
    }

    if (hasNewOrder) {
      return 'new';
    } else if (hasActiveOrder) {
      return 'active';
    } else {
      return 'none';
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user['username'] ?? 'User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email'] ?? 'N/A'}'),
                SizedBox(height: 10),
                Text('Taste Profile:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildTasteProfile(user['tasteProfile'] as Map<String, dynamic>?),
                SizedBox(height: 10),
                Text('Orders:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<List<DocumentSnapshot>>(
                  future: _firestoreService.getOrdersForUser(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final orders = snapshot.data ?? [];

                    if (orders.isEmpty) {
                      return Text('No orders available');
                    }

                    return Column(
                      children: orders.map((orderDoc) {
                        final order = orderDoc.data() as Map<String, dynamic>;
                        final orderId = orderDoc.id;

                        return ListTile(
                          title: Text('Address: ${order['address'] ?? 'N/A'}'),
                          subtitle: Text('Status: ${order['status'] ?? 'N/A'}'),
                          trailing: _buildOrderActions(order, orderId, userId),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasteProfile(Map<String, dynamic>? tasteProfile) {
    if (tasteProfile == null) {
      return Text('No taste profile available');
    }

    List<Widget> profileWidgets = [];

    List<String> genres = List<String>.from(tasteProfile['genres'] ?? []);
    profileWidgets.add(Text('Genres: ${genres.isNotEmpty ? genres.join(', ') : 'N/A'}'));

    List<String> decades = List<String>.from(tasteProfile['decades'] ?? []);
    profileWidgets.add(Text('Decades: ${decades.isNotEmpty ? decades.join(', ') : 'N/A'}'));

    String albumsListened = tasteProfile['albumsListened'] ?? 'N/A';
    profileWidgets.add(Text('Albums Listened: $albumsListened'));

    String musicalBio = tasteProfile['musicalBio'] ?? 'N/A';
    profileWidgets.add(Text('Musical Bio: $musicalBio'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: profileWidgets,
    );
  }

  Widget _buildOrderActions(Map<String, dynamic> order, String orderId, String userId) {
    if (order['status'] == 'returned' && (order['returnConfirmed'] ?? false) == false) {
      return ElevatedButton(
        onPressed: () {
          _confirmReturn(orderId);
        },
        child: Text('Confirm Return'),
      );
    } else if (order['status'] == 'new') {
      return ElevatedButton(
        onPressed: () {
          _showSendAlbumDialog(orderId, order['address'], userId);
        },
        child: Text('Send Album'),
      );
    } else {
      return Text('No action needed');
    }
  }

  void _showAddAlbumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Album'),
          content: Form(
            key: _albumFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField('Artist', (value) => _artist = value),
                  _buildTextField('Album Name', (value) => _albumName = value),
                  _buildTextField('Release Year', (value) => _releaseYear = value),
                  _buildTextField('Quality', (value) => _quality = value),
                  _buildTextField('Cover URL', (value) => _coverUrl = value),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _albumFormKey.currentState?.reset();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addAlbum();
                Navigator.of(context).pop();
                _albumFormKey.currentState?.reset();
              },
              child: Text('Add Album'),
            ),
          ],
        );
      },
    );
  }

  void _showSendAlbumDialog(String orderId, String address, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send Album'),
          content: Form(
            key: _albumFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField('Artist', (value) => _artist = value),
                  _buildTextField('Album Name', (value) => _albumName = value),
                  _buildTextField('Release Year', (value) => _releaseYear = value),
                  _buildTextField('Quality', (value) => _quality = value),
                  _buildTextField('Cover URL', (value) => _coverUrl = value),
                  _buildTextField('Album ID (if reusing existing album)', (value) => _albumId = value),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _albumFormKey.currentState?.reset();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _sendAlbum(orderId, address, userId);
                Navigator.of(context).pop();
                _albumFormKey.currentState?.reset();
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onChanged: (value) {
        setState(() {
          onChanged(value);
        });
      },
    );
  }

  Future<void> _sendAlbum(String orderId, String address, String userId) async {
    String albumId;

    if (_albumId.isNotEmpty) {
      albumId = _albumId;
    } else {
      DocumentReference albumRef = await _firestoreService.addAlbum(_artist, _albumName, _releaseYear, _quality, _coverUrl);
      albumId = albumRef.id;
    }

    await _firestoreService.updateOrderWithAlbum(orderId, albumId);
    setState(() {});
  }

  Future<void> _addAlbum() async {
    if (_albumFormKey.currentState?.validate() ?? false) {
      _albumFormKey.currentState?.save();
      await _firestoreService.addAlbum(_artist, _albumName, _releaseYear, _quality, _coverUrl);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Album added successfully')));
      setState(() {});
    }
  }

  Future<void> _confirmReturn(String orderId) async {
    await _firestoreService.confirmReturn(orderId);
    setState(() {});
  }
}

class AlbumListScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Album List'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _firestoreService.getAllAlbums(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final albums = snapshot.data ?? [];

          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(album['albumName']),
                subtitle: Text('Artist: ${album['artist']} - Year: ${album['releaseYear']} - Quality: ${album['quality']}'),
              );
            },
          );
        },
      ),
    );
  }
}
