import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  await updateOrdersWithTimestamps();
  print("Orders updated successfully!");
}

Future<void> updateOrdersWithTimestamps() async {
  final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance.collection('orders').get();
  final WriteBatch batch = FirebaseFirestore.instance.batch();

  for (final doc in ordersSnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;

    if (!data.containsKey('updatedAt')) {
      // Set updatedAt to timestamp if available, otherwise use server timestamp
      final Timestamp? existingTimestamp = data['timestamp'] as Timestamp?;
      batch.update(doc.reference, {
        'updatedAt': existingTimestamp ?? FieldValue.serverTimestamp(),
      });
    }
  }

  await batch.commit();
}
