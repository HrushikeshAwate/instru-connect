const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
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
