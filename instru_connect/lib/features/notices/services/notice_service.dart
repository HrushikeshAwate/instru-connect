import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/services/notification_service.dart';

class NoticeService {
  // ✅ DEFINE FIRESTORE INSTANCE
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ---------- READ (used by list screen) ----------
  Future<QuerySnapshot> fetchNoticesSnapshot({
    required String departmentId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query query = _firestore
        .collection(FirestoreCollections.notices)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  // ---------- WRITE ----------
  Future<String> createNotice({
    required String title,
    required String body,
    required String departmentId,
    required List<String> batchIds,
  }) async {
    final docRef = await _firestore
        .collection(FirestoreCollections.notices)
        .add({
          'title': title.trim(),
          'body': body.trim(),
          'departmentId': departmentId,
          'batchIds': batchIds,
          'createdAt': Timestamp.now(),
          'deleteAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
          'attachments': [],
        });

    final noticeId = docRef.id;

    // Notify only students/CR in the selected batches
    final uids =
        await _notificationService.fetchStudentCrUidsByBatchIds(batchIds);
    await _notificationService.createNotificationsForUsers(
      uids: uids,
      title: 'New Notice',
      body: title.trim(),
      type: 'notice',
      data: {
        'noticeId': noticeId,
        'batchIds': batchIds,
      },
    );

    return noticeId;
  }

  Future<List<Notice>> fetchRecentNotices({
    // required String departmentId,
    int limit = 3,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.notices)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
  }

  Future<void> addAttachment({
    required String noticeId,
    required String attachmentUrl,
  }) async {
    await _firestore
        .collection(FirestoreCollections.notices)
        .doc(noticeId)
        .update({
          'attachments': FieldValue.arrayUnion([attachmentUrl]),
        });
  }
}
