import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitAttendance({
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
  }) async {
    final writeBatch = _db.batch();
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];
    final attendanceDocId = "${dateKey}_${subjectName}_${DateTime.now().millisecondsSinceEpoch}";

    // Target Path: batches -> {batchId} -> attendance -> {docId}
    final attendanceRef = _db
        .collection('batches')
        .doc(batchId)
        .collection('attendance')
        .doc(attendanceDocId);

    writeBatch.set(attendanceRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'subject': subjectName,
      'absentUids': absentStudentUids,
      'date': dateKey,
    });

    // Update individual student stats per subject
    for (String uid in allStudentUids) {
      final userRef = _db.collection('users').doc(uid);
      bool isAbsent = absentStudentUids.contains(uid);

      writeBatch.set(userRef, {
        'subjects': {
          subjectName: {
            'total': FieldValue.increment(1),
            'attended': isAbsent ? FieldValue.increment(0) : FieldValue.increment(1),
          }
        }
      }, SetOptions(merge: true));
    }
    await writeBatch.commit();
  }
}