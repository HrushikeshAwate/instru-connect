import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStudentAttendance(
    String studentId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('markedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStudentSubjectAttendance({
    required String studentId,
    required String subjectId,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('markedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSubjectSessions({
    required String batchId,
    required String subjectName,
  }) {
    return _db
        .collection('sessions')
        .where('batchId', isEqualTo: batchId)
        .where('subjectName', isEqualTo: subjectName.trim())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
