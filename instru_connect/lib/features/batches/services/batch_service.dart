import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Assign ONE student to a batch (admin use)
  Future<void> assignStudentToBatch({
    required String studentUid,
    required String batchId,
  }) async {
    final userRef = _db.collection('users').doc(studentUid);
    final batchRef = _db.collection('batches').doc(batchId);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final batchSnap = await tx.get(batchRef);

      if (!userSnap.exists) {
        throw Exception('User not found');
      }
      if (!batchSnap.exists) {
        throw Exception('Batch not found');
      }

      final role = userSnap['role'];
      if (role != 'student' && role != 'cr') {
        throw Exception('Only students can be assigned to batches');
      }

      tx.update(userRef, {
        'batchId': batchId,
        'academicYear': batchSnap['currentYear'],
      });
    });
  }

  /// BULK assign students to ONE batch
  Future<void> bulkAssignStudents({
    required List<String> studentUids,
    required String batchId,
  }) async {
    final batchRef = _db.collection('batches').doc(batchId);
    final batchSnap = await batchRef.get();

    if (!batchSnap.exists) {
      throw Exception('Batch not found');
    }

    final int academicYear = batchSnap['currentYear'];
    final batch = _db.batch();

    for (final uid in studentUids) {
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'batchId': batchId,
        'academicYear': academicYear,
      });
    }

    await batch.commit();
  }
}
