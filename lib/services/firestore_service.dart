import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if a username exists in the usernames collection
  Future<bool> checkUsernameExists(String username) async {
    final doc = await _firestore.collection('usernames').doc(username).get();
    return doc.exists;
  }

  // Add a username to the usernames collection
  Future<void> addUsername(String username, String userId) async {
    await _firestore.collection('usernames').doc(username).set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a username from the usernames collection
  Future<void> removeUsername(String username) async {
    await _firestore.collection('usernames').doc(username).delete();
  }

  // Add user to the users collection
// Add user to the users collection and create public profile
  Future<void> addUser(
      String userId, String username, String email, String country) async {
    // Create the main user document with private data
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'country': country,
      'addresses': [],
      'hasOrdered': false,
      'tasteProfile': null,
      'createdAt': FieldValue.serverTimestamp(),
      // Add other private user-related fields as needed
    });

    // Create the public profile in the 'public' subcollection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('public')
        .doc('profile')
        .set({
      'username': username,
      // Add other public fields if necessary
    });
  }

  Future<void> updateOrderReturnStatus(
      String orderId, bool returnConfirmed) async {
    await _firestore.collection('orders').doc(orderId).update({
      'returnConfirmed': returnConfirmed,
      'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
    });
  }

  Future<void> addOrder(String userId, String address) async {
    await _firestore.collection('orders').add({
      'userId': userId,
      'address': address,
      'status': 'new',
      'timestamp': FieldValue.serverTimestamp(),
      'details': {},
    });

    await _firestore.collection('users').doc(userId).update({
      'hasOrdered': true,
      'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
    });
  }

  Future<void> updateOrderWithAlbum(String orderId, String albumId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'sent',
      'details.albumId': albumId,
      'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
    });

    if (status == 'returned' || status == 'kept') {
      DocumentSnapshot orderDoc =
          await _firestore.collection('orders').doc(orderId).get();
      String userId = orderDoc['userId'];
      await _firestore.collection('users').doc(userId).update({
        'hasOrdered': false,
        'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
      });
    }
  }

  Future<void> submitFeedback(
      String orderId, Map<String, dynamic> feedback) async {
    await _firestore.collection('orders').doc(orderId).update({
      'feedback': feedback,
      'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
    });
  }

  Future<bool> isAdmin(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('admins').doc(userId).get();
    return doc.exists;
  }

  Future<List<DocumentSnapshot>> getAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs;
  }

  Future<DocumentSnapshot> getOrderById(String orderId) async {
    return await _firestore.collection('orders').doc(orderId).get();
  }

  Future<List<DocumentSnapshot>> getOrdersForUser(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot>> getUnfulfilledOrders() async {
    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'new')
        .get();
    return snapshot.docs;
  }

  Future<DocumentReference> addAlbum(String artist, String albumName,
      String releaseYear, String quality, String coverUrl) async {
    DocumentReference albumRef = await _firestore.collection('albums').add({
      'artist': artist,
      'albumName': albumName,
      'releaseYear': releaseYear,
      'quality': quality,
      'coverUrl': coverUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return albumRef;
  }

  Future<void> addToWishlist({
    required String userId,
    required String albumId,
    required String albumName,
    required String albumImageUrl,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(albumId)
        .set({
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'dateAdded': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getAlbumById(String albumId) async {
    return await _firestore.collection('albums').doc(albumId).get();
  }

  Future<List<DocumentSnapshot>> getAllAlbums() async {
    QuerySnapshot snapshot = await _firestore.collection('albums').get();
    return snapshot.docs;
  }

  Future<void> confirmReturn(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'returnConfirmed': true,
        'status': 'returnedConfirmed', // Update the status if needed
        'updatedAt': FieldValue.serverTimestamp(), // Added updatedAt timestamp
      });
    } catch (e) {
      print('Error confirming return: $e');
      throw e;
    }
  }

  Future<List<DocumentSnapshot>> getPreviousAddresses(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()!.containsKey('previousAddresses')) {
      return userDoc['previousAddresses'];
    }
    return [];
  }

  Future<Map<String, int>> getUserAlbumStats(String userId) async {
    final QuerySnapshot keptAlbumsQuery = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'kept')
        .get();

    final QuerySnapshot sentBackAlbumsQuery = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'returnedConfirmed')
        .get();

    return {
      'albumsKept': keptAlbumsQuery.docs.length,
      'albumsSentBack': sentBackAlbumsQuery.docs.length,
    };
  }

  Future<DocumentSnapshot> getUserStats(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
}
