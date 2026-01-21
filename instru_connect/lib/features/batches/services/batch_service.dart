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

      if (!userSnap.exists) throw Exception('User not found');
      if (!batchSnap.exists) throw Exception('Batch not found');

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

    if (!batchSnap.exists) throw Exception('Batch not found');

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

  /// FIXED: Submit Attendance and create missing fields
  Future<void> submitAttendance({
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
  }) async {
    final writeBatch = _db.batch();

    // Create a unique ID for this attendance session
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];
    final attendanceDocId = "${dateKey}_${subjectName}_${DateTime.now().millisecondsSinceEpoch}";

    final attendanceRef = _db
        .collection('batches')
        .doc(batchId)
        .collection('attendance')
        .doc(attendanceDocId);

    // 1. Record the session details
    writeBatch.set(attendanceRef, {
      'date': FieldValue.serverTimestamp(),
      'subject': subjectName,
      'absentStudents': absentStudentUids,
    });

    // 2. Update EVERY student's profile
    for (String uid in allStudentUids) {
      final userRef = _db.collection('users').doc(uid);
      bool isAbsent = absentStudentUids.contains(uid);

      // Using .set with SetOptions(merge: true) is the fix!
      // This creates 'totalClasses' and 'attendedClasses' if they are missing.
      writeBatch.set(userRef, {
        'totalClasses': FieldValue.increment(1),
        'attendedClasses': isAbsent ? FieldValue.increment(0) : FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    await writeBatch.commit();
  }
}