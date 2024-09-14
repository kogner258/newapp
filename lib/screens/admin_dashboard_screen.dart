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

  Future<void> _confirmReturn(String orderId) async {
    await _firestoreService.confirmReturn(orderId);
    setState(() {});
  }

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
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: showUnfulfilledOrders ? _firestoreService.getUnfulfilledOrders() : _firestoreService.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;

                    return ExpansionTile(
                      title: Text('${user['firstName']} ${user['lastName']}'),
                      subtitle: Text(user['email']),
                      children: [
                        ListTile(
                          title: Text('Taste Profile'),
                          subtitle: user['tasteProfile'] != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Genres: ${(user['tasteProfile']['genres'] as List<dynamic>).join(', ')}'),
                                    Text('Albums Listened: ${user['tasteProfile']['albumsListened']}'),
                                  ],
                                )
                              : Text('No taste profile available'),
                        ),
                        FutureBuilder<List<DocumentSnapshot>>(
                          future: _firestoreService.getOrdersForUser(userId),
                          builder: (context, orderSnapshot) {
                            if (!orderSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final orders = orderSnapshot.data ?? [];

                            return ExpansionTile(
                              title: Text('Orders (${orders.length})'),
                              children: orders.map((orderDoc) {
                                final order = orderDoc.data() as Map<String, dynamic>;
                                final orderId = orderDoc.id;

                                return ListTile(
                                  title: Text(order['address']),
                                  subtitle: Text('Status: ${order['status']}'),
                                  trailing: order['status'] == 'returned' && (order['returnConfirmed'] ?? false) == false
                                      ? ElevatedButton(
                                          onPressed: () {
                                            _confirmReturn(orderId);
                                          },
                                          child: Text('Confirm Return'),
                                        )
                                      : order['status'] == 'new'
                                          ? ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('Send Album'),
                                                      content: Form(
                                                        key: _albumFormKey,
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Artist'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _artist = value;
                                                                });
                                                              },
                                                            ),
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Album Name'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _albumName = value;
                                                                });
                                                              },
                                                            ),
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Release Year'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _releaseYear = value;
                                                                });
                                                              },
                                                            ),
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Quality'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _quality = value;
                                                                });
                                                              },
                                                            ),
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Album ID (if reusing existing album)'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _albumId = value;
                                                                });
                                                              },
                                                            ),
                                                            TextFormField(
                                                              decoration: InputDecoration(labelText: 'Cover URL'),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _coverUrl = value;
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Text('Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            if (_albumFormKey.currentState?.validate() ?? false) {
                                                              _albumFormKey.currentState?.save();
                                                              _sendAlbum(orderId, order['address'], userId);
                                                              Navigator.of(context).pop();
                                                            }
                                                          },
                                                          child: Text('Send'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text('Mark as Sent'),
                                            )
                                          : Text('Order Sent'),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
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