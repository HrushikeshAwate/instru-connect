import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/services/notification_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();

  String get _normalizedRole => (CurrentUser.role ?? '').trim().toLowerCase();

  bool get canManageBatches =>
      _normalizedRole == AppRoles.admin || _normalizedRole == AppRoles.faculty;

  bool get canDeleteBatches =>
      _normalizedRole == AppRoles.admin || _normalizedRole == AppRoles.faculty;

  bool get canManageSubjects =>
      _normalizedRole == AppRoles.admin || _normalizedRole == AppRoles.faculty;

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
    }
    return <String, dynamic>{};
  }

  Future<void> promoteAllStudents() async {
    final batchesSnapshot = await _db.collection('batches').get();
    final Map<int, String> yearToBatchId = {};

    for (final doc in batchesSnapshot.docs) {
      final data = doc.data();
      final dynamic year = data['currentYear'];
      if (year != null) yearToBatchId[year as int] = doc.id;
    }

    const promotionMap = <int, int>{1: 2, 2: 3, 3: 4, 4: 0};
    final usersSnapshot = await _db
        .collection('users')
        .where('role', whereIn: ['student', 'cr'])
        .get();

    if (usersSnapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final userDoc in usersSnapshot.docs) {
      final String? currentBatchId = userDoc.data()['batchId'];
      if (currentBatchId == null) continue;

      final currentBatchEntry = yearToBatchId.entries.firstWhere(
        (entry) => entry.value == currentBatchId,
        orElse: () => const MapEntry(-1, ''),
      );

      if (currentBatchEntry.key == -1) continue;
      final nextYear = promotionMap[currentBatchEntry.key];
      final nextBatchId = yearToBatchId[nextYear];

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

    final academicYear = (batchSnap.get('currentYear') as num).toInt();
    final batch = _db.batch();

    for (final uid in studentUids) {
      batch.update(_db.collection('users').doc(uid), {
        'batchId': batchId,
        'academicYear': academicYear,
      });
    }
    await batch.commit();
  }

  Future<int> submitAttendance({
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
  }) async {
    final sessionId = await createSession(
      batchId: batchId,
      subjectName: subjectName,
      totalStudents: allStudentUids.length,
    );

    await _markAttendanceForSession(
      sessionId: sessionId,
      batchId: batchId,
      subjectName: subjectName,
      absentStudentUids: absentStudentUids,
      allStudentUids: allStudentUids,
      isUpdate: false,
    );
    return 1;
  }

  Future<String> createSession({
    required String batchId,
    required String subjectName,
    int? totalStudents,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final normalizedSubject = subjectName.trim();
    final subjectDoc = await _resolveSubject(batchId, normalizedSubject);
    if (subjectDoc == null) {
      throw Exception('Subject not found for this batch');
    }

    final sessionDate = date ?? DateTime.now();
    final dateKey = _dateKey(sessionDate);
    final sessionRef = _db.collection('sessions').doc();
    final defaultStart = startTime ?? DateTime.now();
    final defaultEnd = endTime ?? defaultStart.add(const Duration(minutes: 50));

    await sessionRef.set({
      'sessionId': sessionRef.id,
      'batchId': batchId,
      'subjectId': subjectDoc.id,
      'subjectName': normalizedSubject,
      'facultyId': _auth.currentUser?.uid,
      'date': dateKey,
      'startTime': Timestamp.fromDate(defaultStart),
      'endTime': Timestamp.fromDate(defaultEnd),
      'sessionNumber': 1,
      'totalStudents': totalStudents ?? 0,
      'presentCount': 0,
      'absentCount': 0,
      'absentStudentIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return sessionRef.id;
  }

  Future<void> updateAttendance({
    required String batchId,
    required String docId,
    required String subjectName,
    required List<String> newAbsentUids,
    required List<String> allStudentUids,
  }) async {
    await _markAttendanceForSession(
      sessionId: docId,
      batchId: batchId,
      subjectName: subjectName,
      absentStudentUids: newAbsentUids,
      allStudentUids: allStudentUids,
      isUpdate: true,
    );
  }

  Future<void> deleteAttendance(String batchId, String docId) async {
    final sessionRef = _db.collection('sessions').doc(docId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    final sessionData = sessionSnap.data()!;
    final recordBatchId = (sessionData['batchId'] ?? '').toString();
    if (recordBatchId.isNotEmpty && recordBatchId != batchId) {
      throw Exception('Attendance record does not belong to this batch');
    }

    final subjectId = (sessionData['subjectId'] ?? '').toString();
    final subjectName = (sessionData['subjectName'] ?? '').toString().trim();

    final attendanceSnap = await _db
        .collection('attendance')
        .where('sessionId', isEqualTo: docId)
        .get();

    final impactedUids = attendanceSnap.docs
        .map((doc) => (doc.data()['studentId'] ?? '').toString())
        .where((uid) => uid.isNotEmpty)
        .toList();

    for (final attendanceDoc in attendanceSnap.docs) {
      await attendanceDoc.reference.delete();
    }
    await sessionRef.delete();

    await _rebuildAttendanceCacheForUsers(
      uids: impactedUids,
      subjectId: subjectId,
      subjectName: subjectName,
    );
  }

  Future<void> deleteSubjectCascade({
    required String batchId,
    required String subjectId,
    required String subjectName,
  }) async {
    if (!canManageSubjects) {
      throw Exception('Only admin or faculty can delete subjects.');
    }

    final normalizedSubject = subjectName.trim();

    final sessionSnap = await _db
        .collection('sessions')
        .where('batchId', isEqualTo: batchId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    final attendanceBySubjectSnap = await _db
        .collection('attendance')
        .where('batchId', isEqualTo: batchId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    final impactedUids = <String>{
      ...attendanceBySubjectSnap.docs
          .map((doc) => (doc.data()['studentId'] ?? '').toString())
          .where((uid) => uid.isNotEmpty),
    };

    await _deleteDocumentsSequentially([
      ...attendanceBySubjectSnap.docs.map((doc) => doc.reference),
      ...sessionSnap.docs.map((doc) => doc.reference),
      _db.collection('subjects').doc(subjectId),
    ]);

    await _activityNotifications.notifyUsers(
      uids: impactedUids,
      title: 'Subject Removed',
      body: normalizedSubject,
      type: 'subject_deleted',
      data: {
        'batchId': batchId,
        'subjectId': subjectId,
        'subjectName': normalizedSubject,
      },
    );

    for (final uid in impactedUids) {
      final userRef = _db.collection('users').doc(uid);
      await userRef.set({
        'subjects': {normalizedSubject: FieldValue.delete()},
        'attendanceAlerts': {normalizedSubject: FieldValue.delete()},
      }, SetOptions(merge: true));
    }

    await _rebuildAttendanceCacheForUsers(
      uids: impactedUids.toList(),
      subjectId: subjectId,
      subjectName: normalizedSubject,
    );
  }

  Future<void> deleteSubjectsCascade({
    required String batchId,
    required List<Map<String, String>> subjects,
  }) async {
    if (!canManageSubjects) {
      throw Exception('Only admin or faculty can delete subjects.');
    }

    if (subjects.isEmpty) return;

    for (final subject in subjects) {
      await deleteSubjectCascade(
        batchId: batchId,
        subjectId: (subject['id'] ?? '').trim(),
        subjectName: (subject['name'] ?? '').trim(),
      );
    }
  }

  Future<void> deleteBatchCascade({
    required String batchId,
  }) async {
    if (!canDeleteBatches) {
      throw Exception('Only admin or faculty can delete batches.');
    }

    final batchRef = _db.collection('batches').doc(batchId);
    final batchSnap = await batchRef.get();
    if (!batchSnap.exists) return;

    final subjectSnap = await _db
        .collection('subjects')
        .where('batchId', isEqualTo: batchId)
        .get();
    final sessionSnap = await _db
        .collection('sessions')
        .where('batchId', isEqualTo: batchId)
        .get();
    final attendanceSnap = await _db
        .collection('attendance')
        .where('batchId', isEqualTo: batchId)
        .get();
    final usersSnap = await _db
        .collection('users')
        .where('batchId', isEqualTo: batchId)
        .get();

    final impactedUserIds = usersSnap.docs.map((doc) => doc.id).toSet();

    await _deleteDocumentsSequentially([
      ...attendanceSnap.docs.map((doc) => doc.reference),
      ...sessionSnap.docs.map((doc) => doc.reference),
      ...subjectSnap.docs.map((doc) => doc.reference),
      batchRef,
    ]);

    await _activityNotifications.notifyUsers(
      uids: impactedUserIds,
      title: 'Batch Removed',
      body: (batchSnap.data()?['name'] ?? 'Your batch').toString(),
      type: 'batch_deleted',
      data: {
        'batchId': batchId,
      },
    );

    for (final userDoc in usersSnap.docs) {
      await userDoc.reference.set({
        'batchId': null,
        'academicYear': null,
        'subjects': <String, dynamic>{},
        'attendanceAlerts': <String, dynamic>{},
        'totalClasses': 0,
        'attendedClasses': 0,
      }, SetOptions(merge: true));
    }

    for (final uid in impactedUserIds) {
      await _rebuildClearedAttendanceCache(uid: uid);
    }
  }

  Future<void> deleteBatchesCascade({
    required List<String> batchIds,
  }) async {
    if (!canDeleteBatches) {
      throw Exception('Only admin or faculty can delete batches.');
    }

    final ids = batchIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    for (final batchId in ids) {
      await deleteBatchCascade(batchId: batchId);
    }
  }

  Future<void> _markAttendanceForSession({
    required String sessionId,
    required String batchId,
    required String subjectName,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
    required bool isUpdate,
  }) async {
    final normalizedSubject = subjectName.trim();
    final subjectDoc = await _resolveSubject(batchId, normalizedSubject);
    if (subjectDoc == null) {
      throw Exception('Subject not found for this batch');
    }

    final sessionRef = _db.collection('sessions').doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      throw Exception('Session not found');
    }

    final sessionData = sessionSnap.data()!;
    final recordBatchId = (sessionData['batchId'] ?? '').toString();
    if (recordBatchId.isNotEmpty && recordBatchId != batchId) {
      throw Exception('Attendance record does not belong to this batch');
    }

    final markedAt = FieldValue.serverTimestamp();
    final writeBatch = _db.batch();

    for (final uid in allStudentUids) {
      final isAbsent = absentStudentUids.contains(uid);
      final attendanceRef = _db
          .collection('attendance')
          .doc('${sessionId}_$uid');

      writeBatch.set(attendanceRef, {
        'attendanceId': attendanceRef.id,
        'sessionId': sessionId,
        'batchId': batchId,
        'subjectId': subjectDoc.id,
        'subjectName': normalizedSubject,
        'studentId': uid,
        'facultyId': _auth.currentUser?.uid,
        'status': isAbsent ? 'Absent' : 'Present',
        'date': sessionData['date'],
        'startTime': sessionData['startTime'],
        'endTime': sessionData['endTime'],
        'markedAt': markedAt,
        'updatedAt': markedAt,
      }, SetOptions(merge: true));
    }

    writeBatch.update(sessionRef, {
      'subjectId': subjectDoc.id,
      'subjectName': normalizedSubject,
      'facultyId': _auth.currentUser?.uid,
      'totalStudents': allStudentUids.length,
      'presentCount': allStudentUids.length - absentStudentUids.length,
      'absentCount': absentStudentUids.length,
      'absentStudentIds': absentStudentUids,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await writeBatch.commit();

    await _rebuildAttendanceCacheForUsers(
      uids: allStudentUids,
      subjectId: subjectDoc.id,
      subjectName: normalizedSubject,
    );

    await _notifyAttendanceRecorded(
      subject: normalizedSubject,
      absentStudentUids: absentStudentUids,
      allStudentUids: allStudentUids,
      isUpdate: isUpdate,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveSubject(
    String batchId,
    String subjectName,
  ) async {
    final snapshot = await _db
        .collection('subjects')
        .where('batchId', isEqualTo: batchId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final normalizedTarget = subjectName.trim().toLowerCase();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().trim().toLowerCase();
      if (name == normalizedTarget) {
        return doc;
      }
    }

    return snapshot.docs.first;
  }

  Future<void> _rebuildAttendanceCacheForUsers({
    required List<String> uids,
    required String subjectId,
    required String subjectName,
  }) async {
    for (final uid in uids.toSet()) {
      if (uid.trim().isEmpty) continue;
      await _rebuildUserAttendanceCache(
        uid: uid,
        subjectId: subjectId,
        subjectName: subjectName,
      );
    }
  }

  Future<void> _rebuildUserAttendanceCache({
    required String uid,
    required String subjectId,
    required String subjectName,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) return;

    final overallAttendance = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: uid)
        .get();

    final totalClasses = overallAttendance.docs.length;
    final overallRecords = overallAttendance.docs
        .map((doc) => doc.data())
        .toList();
    final attendedClasses = overallRecords.where((data) {
      final status = (data['status'] ?? '').toString().toLowerCase();
      return status == 'present' || status == 'late';
    }).length;

    final subjectRecords = overallRecords.where((data) {
      return (data['subjectId'] ?? '').toString() == subjectId;
    }).toList();
    final subjectTotal = subjectRecords.length;
    final subjectAttended = subjectRecords.where((data) {
      final status = (data['status'] ?? '').toString().toLowerCase();
      return status == 'present' || status == 'late';
    }).length;

    await userRef.set({
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'subjects': {
        subjectName: {
          'total': subjectTotal,
          'attended': subjectAttended,
          'percentage': subjectTotal == 0
              ? 0
              : (subjectAttended / subjectTotal) * 100,
          'subjectId': subjectId,
        },
      },
    }, SetOptions(merge: true));

    await _checkLowAttendanceForUser(
      uid: uid,
      subject: subjectName,
      total: subjectTotal,
      attended: subjectAttended,
    );
  }

  Future<void> _checkLowAttendanceForUser({
    required String uid,
    required String subject,
    required int total,
    required int attended,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();
    if (!snap.exists) return;

    final data = _asStringDynamicMap(snap.data());
    final alerts = _asStringDynamicMap(data['attendanceAlerts']);

    if (total == 0) {
      await userRef.set({
        'attendanceAlerts': {subject: false},
      }, SetOptions(merge: true));
      return;
    }

    final percentage = (attended / total) * 100;
    final alreadyAlerted = alerts[subject] == true;

    if (percentage < 75 && !alreadyAlerted) {
      await _notificationService.createUserNotification(
        uid: uid,
        title: 'Low Attendance',
        body: '$subject is at ${percentage.toStringAsFixed(1)}%',
        type: 'low_attendance',
        data: {'subject': subject, 'percentage': percentage},
      );
      await userRef.set({
        'attendanceAlerts': {subject: true},
      }, SetOptions(merge: true));
    } else if (percentage >= 75 && alreadyAlerted) {
      await userRef.set({
        'attendanceAlerts': {subject: false},
      }, SetOptions(merge: true));
    }
  }

  Future<void> _notifyAttendanceRecorded({
    required String subject,
    required List<String> absentStudentUids,
    required List<String> allStudentUids,
    required bool isUpdate,
  }) async {
    for (final uid in allStudentUids) {
      final isAbsent = absentStudentUids.contains(uid);
      await _notificationService.createUserNotification(
        uid: uid,
        title: isUpdate
            ? 'Attendance updated successfully'
            : 'Attendance marked successfully',
        body: 'Attendance marked for $subject: ${isAbsent ? 'Absent' : 'Present'}',
        type: isUpdate ? 'attendance_updated' : 'attendance_marked',
        data: {
          'subject': subject,
          'status': isAbsent ? 'absent' : 'present',
        },
      );
    }
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _rebuildClearedAttendanceCache({required String uid}) async {
    final userRef = _db.collection('users').doc(uid);
    await userRef.set({
      'totalClasses': 0,
      'attendedClasses': 0,
      'subjects': <String, dynamic>{},
      'attendanceAlerts': <String, dynamic>{},
    }, SetOptions(merge: true));
  }

  Future<void> _deleteDocumentsSequentially(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    if (refs.isEmpty) return;

    for (final ref in refs) {
      await ref.delete();
    }
  }
}
