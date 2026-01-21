import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final DateTime timestamp;
  final String subject;
  final List<String> absentUids;
  final String date;

  AttendanceRecord({
    required this.id,
    required this.timestamp,
    required this.subject,
    required this.absentUids,
    required this.date,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      subject: data['subject'] ?? '',
      absentUids: List<String>.from(data['absentUids'] ?? []),
      date: data['date'] ?? '',
    );
  }
}