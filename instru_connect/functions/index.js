const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { HttpsError, onCall, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

const { admin, db } = require('./src/shared/firebase');
const { attendanceRouter } = require('./src/routes/attendanceRouter');

exports.sendNotificationOnCreate = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const uid = data.uid;
    if (!uid) return;

    const title = data.title || 'Notification';
    const body = data.body || '';
    const payloadData = {};

    if (data.type) payloadData.type = String(data.type);
    if (data.noticeId) payloadData.noticeId = String(data.noticeId);
    if (data.data && typeof data.data === 'object') {
      for (const [key, value] of Object.entries(data.data)) {
        payloadData[key] = String(value);
      }
    }

    const tokensSnap = await db
      .collection('users')
      .doc(uid)
      .collection('fcmTokens')
      .get();

    if (tokensSnap.empty) return;

    const tokens = tokensSnap.docs.map((doc) => doc.id);
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: payloadData,
    });

    const batch = db.batch();
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          batch.delete(
            db.collection('users').doc(uid).collection('fcmTokens').doc(tokens[idx]),
          );
        }
      }
    });

    await batch.commit();
  },
);

exports.cleanupExpiredNotifications = onSchedule(
  {
    schedule: 'every day 00:00',
    timeZone: 'UTC',
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    while (true) {
      const snapshot = await db
        .collection('notifications')
        .where('deleteAt', '<=', now)
        .limit(500)
        .get();

      if (snapshot.empty) {
        return;
      }

      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  },
);

exports.attendanceApi = onRequest(attendanceRouter);

async function deleteQueryInBatches(query, batchSize = 400) {
  while (true) {
    const snapshot = await query.limit(batchSize).get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

async function deleteStoragePrefix(bucket, prefix) {
  const [files] = await bucket.getFiles({ prefix });
  if (!files.length) return;

  await Promise.all(
    files.map((file) =>
      file.delete({ ignoreNotFound: true }).catch((error) => {
        if (error.code === 404) return;
        throw error;
      }),
    ),
  );
}

exports.deleteOwnAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const bucket = admin.storage().bucket();

  const createdComplaintIds = [];
  const complaintsSnap = await db
    .collection('complaints')
    .where('createdBy', '==', uid)
    .get();
  complaintsSnap.docs.forEach((doc) => createdComplaintIds.push(doc.id));

  await Promise.all([
    deleteQueryInBatches(db.collection('achievements').where('uid', '==', uid)),
    deleteQueryInBatches(db.collection('certifications').where('uid', '==', uid)),
    deleteQueryInBatches(db.collection('notifications').where('uid', '==', uid)),
    deleteQueryInBatches(db.collection('notifications').where('createdBy', '==', uid)),
    deleteQueryInBatches(db.collection('complaints').where('createdBy', '==', uid)),
    deleteQueryInBatches(db.collection('attendance').where('studentId', '==', uid)),
    deleteQueryInBatches(db.collection('attendance').where('facultyId', '==', uid)),
    deleteQueryInBatches(db.collection('attendance_summary').where('studentId', '==', uid)),
    deleteQueryInBatches(db.collection('sessions').where('facultyId', '==', uid)),
    deleteQueryInBatches(db.collection('resources').where('uploadedByUid', '==', uid)),
    deleteQueryInBatches(db.collection('notices').where('createdBy', '==', uid)),
    deleteQueryInBatches(db.collection('events').where('createdBy', '==', uid)),
  ]);

  await Promise.all([
    deleteStoragePrefix(bucket, `achievements/${uid}/`),
    deleteStoragePrefix(bucket, `certifications/${uid}/`),
    ...createdComplaintIds.map((complaintId) =>
      deleteStoragePrefix(bucket, `complaints_media/${complaintId}/`),
    ),
  ]);

  await Promise.all([
    db.collection('profiles').doc(uid).delete().catch(() => {}),
    db.collection('users').doc(uid).delete().catch(() => {}),
  ]);

  try {
    await admin.auth().deleteUser(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  return { success: true };
});
