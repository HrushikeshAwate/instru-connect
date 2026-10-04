import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Assign CR to a student (atomic & safe)
  Future<void> assignCR({
    required String userId,
    required String batchId,
  }) async {
    _throwIfDemoActor();

    final batchRef = _firestore.collection('batches').doc(batchId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final batchSnap = await transaction.get(batchRef);
      final userSnap = await transaction.get(userRef);

      if (!batchSnap.exists) {
        throw Exception('Batch not found');
      }

      _throwIfDemoTarget(userSnap);

      final data = batchSnap.data()!;
      final List<dynamic> crUserIds = List.from(data['crUserIds'] ?? []);
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

      transaction.update(userRef, {'role': 'cr'});
    });
  }

  /// Remove CR role (future use: graduation / admin action)
  Future<void> removeCR({
    required String userId,
    required String batchId,
  }) async {
    _throwIfDemoActor();

    final batchRef = _firestore.collection('batches').doc(batchId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final batchSnap = await transaction.get(batchRef);
      final userSnap = await transaction.get(userRef);
      if (!batchSnap.exists) return;

      _throwIfDemoTarget(userSnap);

      final data = batchSnap.data()!;
      final List<dynamic> crUserIds = List.from(data['crUserIds'] ?? []);

      if (!crUserIds.contains(userId)) return;

      crUserIds.remove(userId);

      transaction.update(batchRef, {
        'crUserIds': crUserIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {'role': 'student'});
    });
  }

  void _throwIfDemoActor() {
    DemoMode.ensureCanWrite();
  }

  void _throwIfDemoTarget(DocumentSnapshot<Map<String, dynamic>> userSnap) {
    final email = userSnap.data()?['email']?.toString();
    if (DemoAccount.isDemoEmail(email)) {
      throw Exception('App Review Demo role cannot be changed.');
    }
  }
}
