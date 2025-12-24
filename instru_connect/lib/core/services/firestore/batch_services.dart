import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Assign CR to a student (atomic & safe)
  Future<void> assignCR({
    required String userId,
    required String batchId,
  }) async {
    final batchRef = _firestore.collection('batches').doc(batchId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final batchSnap = await transaction.get(batchRef);

      if (!batchSnap.exists) {
        throw Exception('Batch not found');
      }

      final data = batchSnap.data()!;
      final List<dynamic> crUserIds =
          List.from(data['crUserIds'] ?? []);
      final int maxCRs = data['maxCRs'] ?? 2;

      if (crUserIds.length >= maxCRs) {
        throw Exception('CR limit reached');
      }

      if (!crUserIds.contains(userId)) {
        crUserIds.add(userId);
      }

      transaction.update(batchRef, {
        'crUserIds': crUserIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'role': 'cr',
      });
    });
  }

  /// Remove CR role (future use: graduation / admin action)
  Future<void> removeCR({
    required String userId,
    required String batchId,
  }) async {
    final batchRef = _firestore.collection('batches').doc(batchId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final batchSnap = await transaction.get(batchRef);
      if (!batchSnap.exists) return;

      final data = batchSnap.data()!;
      final List<dynamic> crUserIds =
          List.from(data['crUserIds'] ?? []);

      if (!crUserIds.contains(userId)) return;

      crUserIds.remove(userId);

      transaction.update(batchRef, {
        'crUserIds': crUserIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'role': 'student',
      });
    });
  }
}
