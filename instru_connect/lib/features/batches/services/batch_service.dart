import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Assigns a student to a batch
  /// Only Admin / Faculty should call this
  Future<void> assignStudentToBatch({
    required String studentUid,
    required String batchId,
  }) async {
    final userRef = _db.collection('users').doc(studentUid);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);

      if (!userSnap.exists) {
        throw Exception('User does not exist');
      }

      final role = userSnap.data()!['role'];

      // Safety check (optional, rules already enforce this)
      if (role != 'student' && role != 'cr') {
        throw Exception('Only students can be assigned to batch');
      }

      tx.update(userRef, {
        'batchId': batchId,
      });
    });
  }

Future<void> removeStudentFromBatch({
  required String studentUid,
}) async {
  final userRef = _db.collection('users').doc(studentUid);

  await _db.runTransaction((tx) async {
    final snap = await tx.get(userRef);

    if (!snap.exists) {
      throw Exception('User not found');
    }

    tx.update(userRef, {
      'batchId': FieldValue.delete(),
    });
  });
}

}

