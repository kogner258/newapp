// lib/services/firestore_service.dart

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

  Future<bool> hasOutstandingOrders(String userId) async {
    QuerySnapshot ordersSnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['sent', 'returned'])
        .get();

    return ordersSnapshot.docs.isNotEmpty;
  }

  Future<void> deleteUserData(String userId) async {
    WriteBatch batch = _firestore.batch();

    // Delete user document in 'users' collection
    DocumentReference userDocRef = _firestore.collection('users').doc(userId);
    batch.delete(userDocRef);

    // Delete public profile
    DocumentReference publicProfileRef = userDocRef.collection('public').doc('profile');
    batch.delete(publicProfileRef);

    // Remove username from 'usernames' collection
    // First, get the username
    DocumentSnapshot publicProfileDoc = await publicProfileRef.get();
    if (publicProfileDoc.exists && publicProfileDoc.data() != null) {
      String username = publicProfileDoc['username'];
      DocumentReference usernameDocRef = _firestore.collection('usernames').doc(username);
      batch.delete(usernameDocRef);
    }

    // Delete user's wishlist items
    CollectionReference wishlistRef = userDocRef.collection('wishlist');
    QuerySnapshot wishlistSnapshot = await wishlistRef.get();
    for (DocumentSnapshot doc in wishlistSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's orders
    QuerySnapshot ordersSnapshot = await _firestore.collection('orders').where('userId', isEqualTo: userId).get();
    for (DocumentSnapshot doc in ordersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getUserPublicProfile(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('public')
        .doc('profile')
        .get();
    return doc.data();
  }

  Future<DocumentSnapshot?> getOrderById(String orderId) async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();
    return doc.exists ? doc : null;
  }

  Future<void> addReview({
    required String albumId,
    required String userId,
    required String orderId,
    required String comment,
  }) {
    final reviewRef = FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('reviews')
        .doc();
    return reviewRef.set({
      'userId': userId,
      'orderId': orderId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateReview({
    required String albumId,
    required String reviewId,
    required String comment,
  }) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('reviews')
        .doc(reviewId)
        .update({'comment': comment, 'timestamp': FieldValue.serverTimestamp()});
  }

  // Remove a username from the usernames collection
  Future<void> removeUsername(String username) async {
    await _firestore.collection('usernames').doc(username).delete();
  }

  /// Cast a new genre vote for a user.
  /// This method should only be called if the user hasn't voted yet.
  Future<void> castGenreVote({
    required String albumId,
    required String userId,
    required String chosenGenre,
  }) async {
    final albumRef = _firestore.collection('albums').doc(albumId);
    final userVoteRef = albumRef.collection('genreUserVotes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // Check if user has already voted
      final userVoteSnap = await transaction.get(userVoteRef);
      if (userVoteSnap.exists) {
        throw Exception("User has already voted");
      }

      // Get the album document
      final albumSnap = await transaction.get(albumRef);
      if (!albumSnap.exists) {
        throw Exception("Album does not exist");
      }

      // Get current genreVotes map, initialize if missing
      Map<String, dynamic> genreVotes = {};
      if (albumSnap.data()!.containsKey('genreVotes')) {
        genreVotes = Map<String, dynamic>.from(albumSnap['genreVotes']);
      }

      // Increment the chosen genre count
      if (genreVotes.containsKey(chosenGenre)) {
        if (genreVotes[chosenGenre] is int) {
          genreVotes[chosenGenre] = genreVotes[chosenGenre]! + 1;
        } else {
          throw Exception("Invalid genreVotes count type for genre '$chosenGenre'. Expected int.");
        }
      } else {
        genreVotes[chosenGenre] = 1;
      }

      // Update genreVotes map in album document using update to prevent overwriting other fields
      transaction.update(albumRef, {'genreVotes': genreVotes});

      // Set user's genre vote
      transaction.set(userVoteRef, {'genre': chosenGenre});
    });
  }

  /// Change the genre vote of a user for a specific album.
  /// This method decrements the old genre's count and increments the new genre's count.
  Future<void> changeGenreVote({
    required String albumId,
    required String userId,
    required String newGenre,
  }) async {
    final albumRef = _firestore.collection('albums').doc(albumId);
    final userVoteRef = albumRef.collection('genreUserVotes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // Get the user's current genre vote
      final userVoteSnap = await transaction.get(userVoteRef);
      if (!userVoteSnap.exists) {
        throw Exception("User has not voted yet");
      }

      final oldGenre = userVoteSnap['genre'] as String?;
      if (oldGenre == null) {
        throw Exception("Existing genre vote is invalid");
      }

      if (oldGenre == newGenre) {
        // No change needed
        print("User '$userId' attempted to change genre to the same genre '$newGenre'. No action taken.");
        return;
      }

      // Get the album document
      final albumSnap = await transaction.get(albumRef);
      if (!albumSnap.exists) {
        throw Exception("Album does not exist");
      }

      // Get current genreVotes map, initialize if missing
      Map<String, dynamic> genreVotes = {};
      if (albumSnap.data()!.containsKey('genreVotes')) {
        genreVotes = Map<String, dynamic>.from(albumSnap['genreVotes']);
      }

      // Decrement the old genre count
      if (genreVotes.containsKey(oldGenre)) {
        if (genreVotes[oldGenre] is int) {
          int oldCount = genreVotes[oldGenre];
          if (oldCount > 1) {
            genreVotes[oldGenre] = oldCount - 1;
          } else {
            // Remove genre if count reaches 0
            genreVotes.remove(oldGenre);
          }
        } else {
          throw Exception("Invalid genreVotes count type for genre '$oldGenre'. Expected int.");
        }
      } else {
        // Handle inconsistency if old genre not found
        print("Inconsistency detected: Old genre '$oldGenre' not found in genreVotes for album '$albumId'.");
      }

      // Increment the new genre count
      if (genreVotes.containsKey(newGenre)) {
        if (genreVotes[newGenre] is int) {
          genreVotes[newGenre] = genreVotes[newGenre]! + 1;
        } else {
          throw Exception("Invalid genreVotes count type for genre '$newGenre'. Expected int.");
        }
      } else {
        genreVotes[newGenre] = 1;
      }

      // Update genreVotes map in album document using update to prevent overwriting other fields
      transaction.update(albumRef, {'genreVotes': genreVotes});

      // Update the user's genre vote
      transaction.update(userVoteRef, {'genre': newGenre});
    });
  }

  /// Retrieve the current genre vote of a user for a specific album.
  Future<String?> getUserGenreVote(String albumId, String userId) async {
    final doc = await _firestore
        .collection('albums')
        .doc(albumId)
        .collection('genreUserVotes')
        .doc(userId)
        .get();
    return doc.exists ? doc['genre'] as String? : null;
  }
  /// Updates the taste profile of a user.
  Future<void> updateTasteProfile(String userId, Map<String, dynamic> tasteProfileData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'tasteProfile': tasteProfileData,
      });
    } catch (e) {
      throw Exception('Failed to update taste profile: $e');
    }
  }
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
      'albumId': albumId,
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
      'genreVotes': {}, // Initialize genreVotes as an empty map
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
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();
      return snapshot.docs;
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
