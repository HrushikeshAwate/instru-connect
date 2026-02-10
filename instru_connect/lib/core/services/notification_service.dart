import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> streamUserNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> createUserNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<void> clearAllForUser(String uid) async {
    final snapshot = await _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) return;

    const int batchSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final chunk = snapshot.docs.sublist(
        i,
        i + batchSize > snapshot.docs.length
            ? snapshot.docs.length
            : i + batchSize,
      );
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> createNotificationsForUsers({
    required List<String> uids,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (uids.isEmpty) return;

    const int batchSize = 400;
    for (var i = 0; i < uids.length; i += batchSize) {
      final chunk = uids.sublist(
        i,
        i + batchSize > uids.length ? uids.length : i + batchSize,
      );

      final batch = _db.batch();
      for (final uid in chunk) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': uid,
          'title': title,
          'body': body,
          'type': type,
          'data': data ?? {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<List<String>> fetchStudentCrUidsByBatchIds(
    List<String> batchIds,
  ) async {
    final uids = <String>{};
    for (final batchId in batchIds) {
      final snapshot = await _db
          .collection('users')
          .where('batchId', isEqualTo: batchId)
          .where('role', whereIn: ['student', 'cr'])
          .get();
      for (final doc in snapshot.docs) {
        uids.add(doc.id);
      }
    }
    return uids.toList();
  }

  Future<List<String>> fetchAllStudentCrUids() async {
    final snapshot = await _db
        .collection('users')
        .where('role', whereIn: ['student', 'cr'])
        .get();

    return snapshot.docs.map((d) => d.id).toList();
  }
}
