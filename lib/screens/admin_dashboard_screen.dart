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

  /// Whether to show ALL users (including those with no orders).
  /// By default, this is false: only new (green), active (yellow), and returned (blue).
  bool showAllUsers = false;

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
              // Optionally add more filtering logic here
            },
          ),
          IconButton(
            icon: Icon(Icons.library_music),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlbumListScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Text('Go to Home Page'),
          ),
          ElevatedButton(
            onPressed: _showAddAlbumDialog,
            child: Text('Add New Album'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUsersWithStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final allUsers = snapshot.data!;

                // Filter out status == 'none' unless we explicitly want all users
                final visibleUsers = showAllUsers
                    ? allUsers
                    : allUsers.where((u) => u['status'] != 'none').toList();

                return ListView.builder(
                  itemCount: visibleUsers.length,
                  itemBuilder: (context, index) {
                    final userMap = visibleUsers[index];
                    final user = userMap['user'] as Map<String, dynamic>;
                    final userId = userMap['userId'] as String;
                    final status = userMap['status'] as String;

                    // Pick dot color based on status
                    Color dotColor;
                    switch (status) {
                      case 'new':
                        dotColor = Colors.green;
                        break;
                      case 'active':
                        dotColor = Colors.yellow;
                        break;
                      case 'returned':
                        dotColor = Colors.blue;
                        break;
                      default:
                        dotColor = Colors.transparent;
                        break;
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
          // Toggle button at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  showAllUsers = !showAllUsers;
                });
              },
              child: Text(
                showAllUsers ? 'Hide Inactive Users' : 'Show All Users',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch all users and determine each user's status:
  ///   - "new" if they have at least one 'new' order
  ///   - "active" if they have at least one 'sent' or 'returned' but no 'new'
  ///   - "returned" if they have at least one 'returned' but no 'new' or 'sent'
  ///     (We’ll refine this logic below so "active" includes 'sent'.)
  ///   - "none" if they have no orders
  /// Then sort so:
  ///   1) "new" first (green), sorted by earliest new order's timestamp ascending
  ///   2) "active" (yellow)
  ///   3) "returned" (blue)
  ///   4) "none" last
  Future<List<Map<String, dynamic>>> _fetchUsersWithStatus() async {
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> usersWithStatus = [];

    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Return both final status and earliest "new" timestamp
      Map<String, dynamic> statusInfo = await _determineUserStatusInfo(userId);

      usersWithStatus.add({
        'userId': userId,
        'user': userData,
        'status': statusInfo['status'], // 'new', 'active', 'returned', or 'none'
        'earliestNewTimestamp': statusInfo['earliestNewTimestamp'], // for sorting
      });
    }

    // We define status sorting: new -> active -> returned -> none
    final statusOrder = ['new', 'active', 'returned', 'none'];

    usersWithStatus.sort((a, b) {
      final statusA = a['status'] as String;
      final statusB = b['status'] as String;

      int indexA = statusOrder.indexOf(statusA);
      int indexB = statusOrder.indexOf(statusB);

      // Compare by status first
      if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }

      // If both are "new", compare earliestNewTimestamp ascending
      if (statusA == 'new') {
        final Timestamp? tsA = a['earliestNewTimestamp'] as Timestamp?;
        final Timestamp? tsB = b['earliestNewTimestamp'] as Timestamp?;

        if (tsA != null && tsB != null) {
          // earlier (older) first
          return tsA.compareTo(tsB);
        } else if (tsA == null && tsB != null) {
          return 1;
        } else if (tsA != null && tsB == null) {
          return -1;
        } else {
          return 0;
        }
      }
      // If same status but not "new", no further sorting needed
      return 0;
    });

    return usersWithStatus;
  }

  /// Determine user status + earliest new order timestamp
  /// Priority:
  ///   1) if user has any "new" order => status = "new"
  ///   2) else if user has any "sent" => status = "active"
  ///   3) else if user has "returned" => status = "returned"
  ///   4) otherwise => "none"
  ///
  /// Also track earliest "new" order timestamp for sorting "new" users.
  Future<Map<String, dynamic>> _determineUserStatusInfo(String userId) async {
    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    bool hasNewOrder = false;
    bool hasActiveOrder = false;
    bool hasReturnedOrder = false;
    Timestamp? earliestNewTimestamp;

    for (var orderDoc in ordersSnapshot.docs) {
      String status = orderDoc['status'] ?? '';
      Timestamp? orderTs = orderDoc['timestamp'];

      if (status == 'new') {
        hasNewOrder = true;
        // Track earliest new order
        if (orderTs != null) {
          if (earliestNewTimestamp == null ||
              orderTs.compareTo(earliestNewTimestamp) < 0) {
            earliestNewTimestamp = orderTs;
          }
        }
      } else if (status == 'sent') {
        hasActiveOrder = true;
      } else if (status == 'returned') {
        // If we already found a 'new' or 'sent', that takes precedence,
        // but we'll track returned separately for fallback
        hasReturnedOrder = true;
      }
    }

    if (hasNewOrder) {
      return {
        'status': 'new',
        'earliestNewTimestamp': earliestNewTimestamp,
      };
    } else if (hasActiveOrder) {
      return {
        'status': 'active',
        'earliestNewTimestamp': null,
      };
    } else if (hasReturnedOrder) {
      return {
        'status': 'returned',
        'earliestNewTimestamp': null,
      };
    } else {
      return {
        'status': 'none',
        'earliestNewTimestamp': null,
      };
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
                Text(
                  'Taste Profile:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
    profileWidgets.add(
      Text('Genres: ${genres.isNotEmpty ? genres.join(', ') : 'N/A'}'),
    );

    List<String> decades = List<String>.from(tasteProfile['decades'] ?? []);
    profileWidgets.add(
      Text('Decades: ${decades.isNotEmpty ? decades.join(', ') : 'N/A'}'),
    );

    String albumsListened = tasteProfile['albumsListened'] ?? 'N/A';
    profileWidgets.add(Text('Albums Listened: $albumsListened'));

    String musicalBio = tasteProfile['musicalBio'] ?? 'N/A';
    profileWidgets.add(Text('Musical Bio: $musicalBio'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: profileWidgets,
    );
  }

  Widget _buildOrderActions(
      Map<String, dynamic> order, String orderId, String userId) {
    // If the order is 'returned' but not confirmed, show "Confirm Return" button
    if (order['status'] == 'returned' && (order['returnConfirmed'] ?? false) == false) {
      return ElevatedButton(
        onPressed: () {
          _confirmReturn(orderId);
        },
        child: Text('Confirm Return'),
      );
    }
    // If the order is 'new', show "Send Album" button
    else if (order['status'] == 'new') {
      return ElevatedButton(
        onPressed: () {
          _showSendAlbumDialog(orderId, order['address'], userId);
        },
        child: Text('Send Album'),
      );
    }
    // Otherwise, no action needed
    else {
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
                  _buildTextField(
                    'Album ID (if reusing existing album)',
                    (value) => _albumId = value,
                  ),
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
      DocumentReference albumRef = await _firestoreService.addAlbum(
        _artist,
        _albumName,
        _releaseYear,
        _quality,
        _coverUrl,
      );
      albumId = albumRef.id;
    }

    // Update order with top-level and details.albumId
    await _firestoreService.updateOrderWithAlbum(orderId, albumId);
    setState(() {});
  }

  Future<void> _addAlbum() async {
    if (_albumFormKey.currentState?.validate() ?? false) {
      _albumFormKey.currentState?.save();
      await _firestoreService.addAlbum(
        _artist,
        _albumName,
        _releaseYear,
        _quality,
        _coverUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Album added successfully')),
      );
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
                title: Text(album['albumName'] ?? 'Unknown'),
                subtitle: Text(
                  'Artist: ${album['artist'] ?? 'N/A'} '
                  '- Year: ${album['releaseYear'] ?? 'N/A'} '
                  '- Quality: ${album['quality'] ?? 'N/A'}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
