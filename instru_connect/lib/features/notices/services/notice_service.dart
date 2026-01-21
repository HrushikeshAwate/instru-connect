import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import '../../../core/constants/firestore_collections.dart';

class NoticeService {
  // ✅ DEFINE FIRESTORE INSTANCE
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          'attachments': [],
        });

    return docRef.id;
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
