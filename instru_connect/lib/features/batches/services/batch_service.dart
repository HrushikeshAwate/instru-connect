import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Assign ONE student to a batch
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

      final data = userSnap.data() as Map<String, dynamic>;
      final role = data['role'];

      if (role != 'student' && role != 'cr') {
        throw Exception('Only students can be assigned to batches');
      }

      tx.update(userRef, {
        'batchId': batchId,
        'academicYear': batchSnap.get('currentYear'),
      });
    });
  }

  /// BULK assign students
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
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'batchId': batchId,
        'academicYear': academicYear,
      });
    }
    await batch.commit();
  }

  /// Submit Attendance with Duplicate Check
  Future<void> submitAttendance({
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
  }) async {
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];

    // Check if attendance for this subject and date already exists
    final existingSnapshot = await _db
        .collection('batches')
        .doc(batchId)
        .collection('attendance')
        .where('date', isEqualTo: dateKey)
        .where('subject', isEqualTo: subjectName)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      throw Exception('Attendance already marked for $subjectName today.');
    }

    final writeBatch = _db.batch();
    final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final attendanceDocId = "${dateKey}_${subjectName}_$uniqueId";

    final attendanceRef = _db
        .collection('batches')
        .doc(batchId)
        .collection('attendance')
        .doc(attendanceDocId);

    // RECORD SESSION
    writeBatch.set(attendanceRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'subject': subjectName,
      'absentUids': absentStudentUids,
      'allStudentUids': allStudentUids,
      'date': dateKey,
    });

    // UPDATE STUDENT STATS
    for (String uid in allStudentUids) {
      final userRef = _db.collection('users').doc(uid);
      bool isAbsent = absentStudentUids.contains(uid);

      writeBatch.set(userRef, {
        'subjects': {
          subjectName: {
            'total': FieldValue.increment(1),
            'attended': isAbsent ? FieldValue.increment(0) : FieldValue.increment(1),
          }
        },
        // Updating global counters if you use them in your dashboard
        'totalClasses': FieldValue.increment(1),
        'attendedClasses': isAbsent ? FieldValue.increment(0) : FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    await writeBatch.commit();
  }

  /// Update existing attendance and correct student stats
  Future<void> updateAttendance({
    required String batchId,
    required String docId,
    required String subjectName,
    required List<String> newAbsentUids,
    required List<String> allStudentUids,
  }) async {
    final docRef = _db.collection('batches').doc(batchId).collection('attendance').doc(docId);
    final snap = await docRef.get();

    if (!snap.exists) throw Exception("Attendance record not found");

    final data = snap.data() as Map<String, dynamic>;
    final List oldAbsentUids = List<String>.from(data['absentUids'] ?? []);

    final writeBatch = _db.batch();

    // 1. Update the session record in history
    writeBatch.update(docRef, {
      'absentUids': newAbsentUids,
      'lastEdited': FieldValue.serverTimestamp(),
    });

    // 2. Adjust individual student counts based on the difference
    for (var uidObj in allStudentUids) {
      final String uid = uidObj.toString();
      final userRef = _db.collection('users').doc(uid);

      bool wasAbsent = oldAbsentUids.contains(uid);
      bool isNowAbsent = newAbsentUids.contains(uid);

      // Change: Student was absent but is now marked present
      if (wasAbsent && !isNowAbsent) {
        writeBatch.set(userRef, {
          'subjects': {
            subjectName: {'attended': FieldValue.increment(1)}
          },
          'attendedClasses': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
      // Change: Student was present but is now marked absent
      else if (!wasAbsent && isNowAbsent) {
        writeBatch.set(userRef, {
          'subjects': {
            subjectName: {'attended': FieldValue.increment(-1)}
          },
          'attendedClasses': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    }

    await writeBatch.commit();
  }

  /// Delete Attendance and revert student counts
  Future<void> deleteAttendance(String batchId, String docId) async {
    final docRef = _db.collection('batches').doc(batchId).collection('attendance').doc(docId);
    final snap = await docRef.get();

    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final String subject = data['subject'] ?? '';
    final List absentUids = data['absentUids'] ?? [];
    final List allUids = data['allStudentUids'] ?? [];

    final writeBatch = _db.batch();

    for (var uidObj in allUids) {
      final String uid = uidObj.toString();
      final userRef = _db.collection('users').doc(uid);
      bool wasAbsent = absentUids.contains(uid);

      // Revert the session (decrement total and attended if they weren't absent)
      writeBatch.set(userRef, {
        'subjects': {
          subject: {
            'total': FieldValue.increment(-1),
            'attended': wasAbsent ? FieldValue.increment(0) : FieldValue.increment(-1),
          }
        },
        'totalClasses': FieldValue.increment(-1),
        'attendedClasses': wasAbsent ? FieldValue.increment(0) : FieldValue.increment(-1),
      }, SetOptions(merge: true));
    }

    writeBatch.delete(docRef);
    await writeBatch.commit();
  }
}