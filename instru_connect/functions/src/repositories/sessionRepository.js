const { db, admin } = require('../shared/firebase');
const { asTimestamp } = require('../shared/time');

async function createSession(data) {
  const ref = db.collection('sessions').doc();
  await ref.set({
    sessionId: ref.id,
    subjectId: data.subjectId,
    facultyId: data.facultyId,
    batchId: data.batchId,
    date: data.date,
    startTime: asTimestamp(data.startTime),
    endTime: asTimestamp(data.endTime),
    status: data.status || 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref.id;
}

async function getSessionById(sessionId) {
  return db.collection('sessions').doc(sessionId).get();
}

async function listSessions({
  subjectId,
  batchId,
  date,
  status,
  limit = 50,
  cursor,
}) {
  let query = db.collection('sessions');

  if (subjectId) query = query.where('subjectId', '==', subjectId);
  if (batchId) query = query.where('batchId', '==', batchId);
  if (date) query = query.where('date', '==', date);
  if (status) query = query.where('status', '==', status);

  query = query.orderBy('createdAt', 'desc').limit(limit);

  if (cursor) {
    query = query.startAfter(asTimestamp(cursor));
  }

  return query.get();
}

async function closeSession(sessionId) {
  await db.collection('sessions').doc(sessionId).update({
    status: 'closed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

module.exports = {
  createSession,
  getSessionById,
  listSessions,
  closeSession,
};
