const { db, admin } = require('../shared/firebase');

function summaryDocId(studentId, subjectId) {
  return `${studentId}_${subjectId}`;
}

async function getSummary(studentId, subjectId) {
  return db
    .collection('attendance_summary')
    .doc(summaryDocId(studentId, subjectId))
    .get();
}

async function upsertSummary({
  studentId,
  subjectId,
  batchId,
  totalSessions,
  presentCount,
  lateCount,
  attendancePercentage,
}) {
  await db
    .collection('attendance_summary')
    .doc(summaryDocId(studentId, subjectId))
    .set({
      studentId,
      subjectId,
      batchId,
      totalSessions,
      presentCount,
      lateCount,
      attendancePercentage,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}

async function listDefaulters({
  threshold,
  subjectId,
  batchId,
  limit = 100,
}) {
  let query = db.collection('attendance_summary');

  if (subjectId) query = query.where('subjectId', '==', subjectId);
  if (batchId) query = query.where('batchId', '==', batchId);

  query = query.where('attendancePercentage', '<', threshold).limit(limit);
  return query.get();
}

module.exports = {
  getSummary,
  upsertSummary,
  listDefaulters,
};
