import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String subjectId;
  final String subjectName;
  final String status;
  final String date;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.status,
    required this.date,
    required this.markedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return AttendanceRecord(
      id: doc.id,
      sessionId: (data['sessionId'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      subjectId: (data['subjectId'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      markedAt: (data['markedAt'] as Timestamp?)?.toDate(),
    );
  }
}
