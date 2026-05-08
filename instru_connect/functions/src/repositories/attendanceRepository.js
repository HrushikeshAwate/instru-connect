const { db, admin } = require('../shared/firebase');
const { asTimestamp } = require('../shared/time');

function attendanceDocId(sessionId, studentId) {
  return `${sessionId}_${studentId}`;
}

async function listAttendanceBySession(sessionId) {
  return db.collection('attendance').where('sessionId', '==', sessionId).get();
}

async function listAttendanceByStudent({
  studentId,
  subjectId,
  limit,
  cursor,
}) {
  let query = db
      .collection('attendance')
      .where('studentId', '==', studentId);

  if (subjectId) {
    query = query.where('subjectId', '==', subjectId);
  }

  query = query.orderBy('markedAt', 'desc');

  if (limit) {
    query = query.limit(limit);
  }

  if (cursor) {
    query = query.startAfter(asTimestamp(cursor));
  }

  return query.get();
}

async function bulkUpsertAttendance({
  session,
  entries,
  markedBy,
}) {
  const bulkWriter = db.bulkWriter();
  const now = admin.firestore.FieldValue.serverTimestamp();

  entries.forEach((entry) => {
    const ref = db.collection('attendance').doc(
      attendanceDocId(session.sessionId, entry.studentId),
    );

    bulkWriter.set(ref, {
      attendanceId: ref.id,
      sessionId: session.sessionId,
      subjectId: session.subjectId,
      facultyId: session.facultyId,
      batchId: session.batchId,
      studentId: entry.studentId,
      status: entry.status,
      markedAt: now,
      markedBy,
      sessionDate: session.date,
      date: session.date,
      startTime: session.startTime || null,
      endTime: session.endTime || null,
      createdAt: now,
      updatedAt: now,
    }, { merge: true });
  });

  await bulkWriter.close();
}

module.exports = {
  attendanceDocId,
  listAttendanceBySession,
  listAttendanceByStudent,
  bulkUpsertAttendance,
};
