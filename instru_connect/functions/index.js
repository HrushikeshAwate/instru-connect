const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

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
    if (data.data && typeof data.data === 'object') {
      for (const [key, value] of Object.entries(data.data)) {
        payloadData[key] = String(value);
      }
    }

    const tokensSnap = await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('fcmTokens')
      .get();

    if (tokensSnap.empty) return;

    const tokens = tokensSnap.docs.map((d) => d.id);

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: payloadData,
    });

    const batch = admin.firestore().batch();
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          const token = tokens[idx];
          const ref = admin
            .firestore()
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token);
          batch.delete(ref);
        }
      }
    });

    await batch.commit();
  }
);
