import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // PRIVATE HELPER METHODS
  // ==========================================

  /// Internal method to handle student stat increments/decrements safely.
  /// This prevents code duplication and "red" errors when updating logic.
  void _updateStudentStats({
    required WriteBatch batch,
    required String uid,
    required String subject,
    required int totalDelta,    // 1 to add, -1 to remove, 0 to stay same
    required int attendedDelta, // 1 to add, -1 to remove, 0 to stay same
  }) {
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {
      'subjects.$subject.total': FieldValue.increment(totalDelta),
      'subjects.$subject.attended': FieldValue.increment(attendedDelta),
      'totalClasses': FieldValue.increment(totalDelta),
      'attendedClasses': FieldValue.increment(attendedDelta),
    });
  }

  // ==========================================
  // BATCH & STUDENT MANAGEMENT
  // ==========================================

  Future<void> promoteAllStudents() async {
    final batchesSnapshot = await _db.collection('batches').get();
    final Map<int, String> yearToBatchId = {};

    for (final doc in batchesSnapshot.docs) {
      final data = doc.data();
      final dynamic year = data['currentYear'];
      if (year != null) yearToBatchId[year as int] = doc.id;
    }

    final Map<int, int> promotionMap = {1: 2, 2: 3, 3: 4, 4: 0};
    final usersSnapshot = await _db.collection('users')
        .where('role', whereIn: ['student', 'cr']).get();

    if (usersSnapshot.docs.isEmpty) return;
    final batch = _db.batch();

    for (final userDoc in usersSnapshot.docs) {
      final String? currentBatchId = userDoc.data()['batchId'];
      if (currentBatchId == null) continue;

      final currentBatchEntry = yearToBatchId.entries.firstWhere(
            (e) => e.value == currentBatchId,
        orElse: () => const MapEntry(-1, ''),
      );

      if (currentBatchEntry.key == -1) continue;
      final int? nextYear = promotionMap[currentBatchEntry.key];
      final String? nextBatchId = yearToBatchId[nextYear];

      if (nextBatchId != null) {
        batch.update(userDoc.reference, {'batchId': nextBatchId});
      }
    }
    await batch.commit();
  }

  Future<void> assignStudentToBatch({
    required String studentUid,
    required String batchId,
  }) async {
    final userRef = _db.collection('users').doc(studentUid);
    final batchRef = _db.collection('batches').doc(batchId);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final batchSnap = await tx.get(batchRef);

      if (!userSnap.exists) throw Exception('User not found');
      if (!batchSnap.exists) throw Exception('Batch not found');

      tx.update(userRef, {
        'batchId': batchId,
        'academicYear': batchSnap.get('currentYear'),
      });
    });
  }

  Future<void> bulkAssignStudents({
    required List<String> studentUids,
    required String batchId,
  }) async {
    final batchRef = _db.collection('batches').doc(batchId);
    final batchSnap = await batchRef.get();
    if (!batchSnap.exists) throw Exception('Batch not found');

    final int academicYear = batchSnap.get('currentYear');
    final batch = _db.batch();

    for (final uid in studentUids) {
      batch.update(_db.collection('users').doc(uid), {
        'batchId': batchId,
        'academicYear': academicYear,
      });
    }
    await batch.commit();
  }

  // ==========================================
  // ATTENDANCE CORE LOGIC
  // ==========================================

  Future<int> submitAttendance({
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
  }) async {
    final normalizedSubject = subjectName.trim();
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];

    final existingSnapshot = await _db.collection('batches').doc(batchId)
        .collection('attendance')
        .where('date', isEqualTo: dateKey)
        .where('subject', isEqualTo: normalizedSubject).get();

    int currentSessionNumber = existingSnapshot.docs.length + 1;
    final writeBatch = _db.batch();
    final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final attendanceDocId = "${dateKey}_${normalizedSubject}_S${currentSessionNumber}_$uniqueId";

    final attendanceRef = _db.collection('batches').doc(batchId).collection('attendance').doc(attendanceDocId);

    writeBatch.set(attendanceRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'subject': normalizedSubject,
      'absentUids': absentStudentUids,
      'allStudentUids': allStudentUids,
      'date': dateKey,
      'sessionNumber': currentSessionNumber,
    });

    for (String uid in allStudentUids) {
      bool isAbsent = absentStudentUids.contains(uid);
      _updateStudentStats(
        batch: writeBatch,
        uid: uid,
        subject: normalizedSubject,
        totalDelta: 1,
        attendedDelta: isAbsent ? 0 : 1,
      );
    }

    await writeBatch.commit();
    return currentSessionNumber;
  }

  Future<void> updateAttendance({
    required String batchId,
    required String docId,
    required String subjectName,
    required List<String> newAbsentUids,
    required List<String> allStudentUids,
  }) async {
    final normalizedSubject = subjectName.trim();
    final docRef = _db.collection('batches').doc(batchId).collection('attendance').doc(docId);
    final snap = await docRef.get();

    if (!snap.exists) throw Exception("Record not found");

    final List oldAbsentUids = List<String>.from(snap.data()?['absentUids'] ?? []);
    final writeBatch = _db.batch();

    writeBatch.update(docRef, {
      'absentUids': newAbsentUids,
      'lastEdited': FieldValue.serverTimestamp(),
    });

    for (var uid in allStudentUids) {
      bool wasAbsent = oldAbsentUids.contains(uid);
      bool isNowAbsent = newAbsentUids.contains(uid);

      if (wasAbsent && !isNowAbsent) {
        _updateStudentStats(batch: writeBatch, uid: uid, subject: normalizedSubject, totalDelta: 0, attendedDelta: 1);
      } else if (!wasAbsent && isNowAbsent) {
        _updateStudentStats(batch: writeBatch, uid: uid, subject: normalizedSubject, totalDelta: 0, attendedDelta: -1);
      }
    }
    await writeBatch.commit();
  }

  Future<void> deleteAttendance(String batchId, String docId) async {
    final docRef = _db.collection('batches').doc(batchId).collection('attendance').doc(docId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final String subject = (data['subject'] as String).trim();
    final List absentUids = List<String>.from(data['absentUids'] ?? []);
    final List allUids = List<String>.from(data['allStudentUids'] ?? []);

    final writeBatch = _db.batch();
    for (var uid in allUids) {
      bool wasAbsent = absentUids.contains(uid);
      _updateStudentStats(
        batch: writeBatch,
        uid: uid,
        subject: subject,
        totalDelta: -1,
        attendedDelta: wasAbsent ? 0 : -1,
      );
    }

    writeBatch.delete(docRef);
    await writeBatch.commit();
  }
}