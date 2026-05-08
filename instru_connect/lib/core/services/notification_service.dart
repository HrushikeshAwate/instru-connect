import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/services/push_notification_service.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _notificationTtl = Duration(days: 40);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  Stream<List<Map<String, dynamic>>> streamUserNotifications(String uid) {
    purgeExpiredNotifications();
    return _notifications
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) {
                final data = d.data();
                data['id'] = d.id;
                return data;
              })
              .where((notification) => !_isExpired(notification))
              .toList(),
        );
  }

  Stream<NotificationCounter> streamUserNotificationCounter(String uid) {
    purgeExpiredNotifications();
    return _notifications.where('uid', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final visibleDocs = snapshot.docs
          .where((doc) => !_isExpired(doc.data()))
          .toList();
      final total = visibleDocs.length;
      final unread = visibleDocs.where((doc) {
        final data = doc.data();
        return data['isRead'] != true;
      }).length;
      return NotificationCounter(total: total, unread: unread);
    });
  }

  Future<void> createUserNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final deleteAt = Timestamp.fromDate(
      DateTime.now().add(_notificationTtl),
    );

    await _notifications.add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'noticeId': data?['noticeId'],
      'createdBy': data?['createdBy'],
      'createdByRole': data?['createdByRole'],
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'deleteAt': deleteAt,
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await PushNotificationService().showLocalNotification(
        title: title,
        body: body,
      );
    }
  }

  Future<void> markRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllReadForUser(String uid) async {
    final snapshot = await _notifications
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    const batchSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final chunk = snapshot.docs.sublist(
        i,
        i + batchSize > snapshot.docs.length
            ? snapshot.docs.length
            : i + batchSize,
      );
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  Future<void> clearAllForUser(String uid) async {
    final snapshot = await _notifications.where('uid', isEqualTo: uid).get();

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

  Future<void> deleteNotificationsForNotice(String noticeId) async {
    final snapshot = await _notifications
        .where('noticeId', isEqualTo: noticeId)
        .get();

    if (snapshot.docs.isEmpty) return;

    const batchSize = 400;
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

  Future<void> purgeExpiredNotifications() async {
    final cutoff = Timestamp.fromDate(DateTime.now());
    final snapshot = await _notifications
        .where('deleteAt', isLessThanOrEqualTo: cutoff)
        .get();

    if (snapshot.docs.isEmpty) return;

    const batchSize = 400;
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
    final deleteAt = Timestamp.fromDate(
      DateTime.now().add(_notificationTtl),
    );

    const int batchSize = 400;
    for (var i = 0; i < uids.length; i += batchSize) {
      final chunk = uids.sublist(
        i,
        i + batchSize > uids.length ? uids.length : i + batchSize,
      );

      final batch = _db.batch();
      for (final uid in chunk) {
        final noticeId = data?['noticeId']?.toString();
        final ref = noticeId != null && noticeId.isNotEmpty
            ? _notifications.doc('${noticeId}_$uid')
            : _notifications.doc();
        batch.set(ref, {
          'uid': uid,
          'title': title,
          'body': body,
          'type': type,
          'noticeId': noticeId,
          'createdBy': data?['createdBy'],
          'createdByRole': data?['createdByRole'],
          'data': data ?? {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'deleteAt': deleteAt,
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

  Future<List<String>> fetchUidsByRoles(List<String> roles) async {
    if (roles.isEmpty) return const [];

    final snapshot = await _db
        .collection('users')
        .where('role', whereIn: roles)
        .get();

    return snapshot.docs.map((d) => d.id).toList();
  }

  Future<List<String>> fetchAllUserUids() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  bool _isExpired(Map<String, dynamic> notification) {
    final deleteAt = notification['deleteAt'];
    if (deleteAt is! Timestamp) return false;
    return !deleteAt.toDate().isAfter(DateTime.now());
  }
}

class NotificationCounter {
  final int total;
  final int unread;

  const NotificationCounter({
    required this.total,
    required this.unread,
  });
}
