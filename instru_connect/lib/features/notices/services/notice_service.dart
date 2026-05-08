import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/constants/firestore_collections.dart';
import 'package:instru_connect/core/services/notification_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/utils/batch_ordering.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  static Map<String, String>? _batchNameCache;

  CollectionReference<Map<String, dynamic>> get _notices =>
      _firestore.collection(FirestoreCollections.notices);

  Future<QuerySnapshot<Map<String, dynamic>>> fetchNoticesSnapshot({
    required String departmentId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query =
        _notices.orderBy('createdAt', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.get();
  }

  Stream<List<Notice>> streamNotices({int? limit}) {
    Query<Map<String, dynamic>> query =
        _notices.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(Notice.fromFirestore).toList(),
        );
  }

  Future<Notice?> fetchNoticeById(String noticeId) async {
    final snapshot = await _notices.doc(noticeId).get();
    if (!snapshot.exists) {
      return null;
    }
    return Notice.fromFirestore(snapshot);
  }

  Future<List<Map<String, String>>> fetchBatchOptions() async {
    final snapshot = await _firestore
        .collection('batches')
        .where('isActive', isEqualTo: true)
        .get();

    final options = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': (data['name'] ?? '').toString(),
      };
    }).toList();

    options.sort((a, b) {
      final aName = a['name'] ?? '';
      final bName = b['name'] ?? '';
      final rankCompare =
          BatchOrdering.rankForName(aName).compareTo(BatchOrdering.rankForName(bName));
      if (rankCompare != 0) return rankCompare;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });
    return options;
  }

  Future<List<String>> fetchOrderedBatchNames(List<String> batchIds) async {
    if (batchIds.isEmpty) return const [];
    await _ensureBatchCache();

    final names = batchIds
        .map((id) => _batchNameCache?[id] ?? id)
        .where((name) => name.trim().isNotEmpty);

    return BatchOrdering.sortBatchNames(names);
  }

  Future<void> _ensureBatchCache() async {
    if (_batchNameCache != null) return;

    final snapshot = await _firestore.collection('batches').get();
    _batchNameCache = {
      for (final doc in snapshot.docs)
        doc.id: (doc.data()['name'] ?? doc.id).toString(),
    };
  }

  Future<String> createNotice({
    required String title,
    required String body,
    required String departmentId,
    required List<String> batchIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to create a notice.');
    }

    final creatorRole = (CurrentUser.role ?? '').toLowerCase();
    if (![AppRoles.admin, AppRoles.faculty, AppRoles.cr].contains(creatorRole)) {
      throw Exception('You are not allowed to create notices.');
    }

    final docRef = await _notices.add({
      'title': title.trim(),
      'body': body.trim(),
      'departmentId': departmentId,
      'batchIds': batchIds,
      'createdAt': FieldValue.serverTimestamp(),
      'deleteAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'createdBy': user.uid,
      'createdByRole': creatorRole,
      'createdByName': CurrentUser.name,
      'attachments': <String>[],
    });

    final noticeId = docRef.id;

    final batchStudentAndCrUids =
        await _notificationService.fetchStudentCrUidsByBatchIds(batchIds);
    final facultyAndAdminUids = await _notificationService.fetchUidsByRoles([
      AppRoles.faculty,
      AppRoles.admin,
    ]);
    final uids = <String>{
      ...batchStudentAndCrUids,
      ...facultyAndAdminUids,
    }.toList();

    await _notificationService.createNotificationsForUsers(
      uids: uids,
      title: 'New Notice',
      body: title.trim(),
      type: 'notice',
      data: {
        'noticeId': noticeId,
        'batchIds': batchIds,
        'createdBy': user.uid,
        'createdByRole': creatorRole,
      },
    );

    return noticeId;
  }

  Future<List<Notice>> fetchRecentNotices({int limit = 3}) async {
    final snapshot =
        await _notices.orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
  }

  Future<void> addAttachment({
    required String noticeId,
    required String attachmentUrl,
  }) async {
    await _notices.doc(noticeId).update({
      'attachments': FieldValue.arrayUnion([attachmentUrl]),
    });
  }

  bool canDeleteNotice(Notice notice) {
    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  Future<void> deleteNotice(String noticeId) async {
    final doc = await _notices.doc(noticeId).get();
    if (!doc.exists) {
      return;
    }

    final notice = Notice.fromFirestore(doc);
    if (!canDeleteNotice(notice)) {
      throw Exception('You are not allowed to delete this notice.');
    }

    await _notices.doc(noticeId).delete();
    try {
      await _notificationService.deleteNotificationsForNotice(noticeId);
    } catch (_) {
      // Notice delete should still succeed even if notification cleanup is blocked.
    }
  }

  Future<void> deleteNotices(List<String> noticeIds) async {
    final role = (CurrentUser.role ?? '').toLowerCase();
    if (role != AppRoles.admin && role != AppRoles.faculty) {
      throw Exception('You are not allowed to delete notices.');
    }

    final normalizedIds = noticeIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedIds.isEmpty) return;

    for (final noticeId in normalizedIds) {
      await _notices.doc(noticeId).delete();
    }

    try {
      await Future.wait(
        normalizedIds.map(_notificationService.deleteNotificationsForNotice),
      );
    } catch (_) {
      // Ignore notification cleanup failures after the notices themselves are deleted.
    }
  }

}
