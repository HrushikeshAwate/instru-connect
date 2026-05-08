const { db, admin } = require('./firebase');

async function authenticateRequest(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    const error = new Error('Missing bearer token');
    error.statusCode = 401;
    throw error;
  }

  const idToken = header.slice('Bearer '.length).trim();
  const decoded = await admin.auth().verifyIdToken(idToken);
  const userDoc = await db.collection('users').doc(decoded.uid).get();
  const role = (userDoc.data()?.role || '').toString().toLowerCase();

  return {
    uid: decoded.uid,
    email: decoded.email || '',
    role,
  };
}

function requireRole(auth, allowedRoles) {
  if (!allowedRoles.includes(auth.role)) {
    const error = new Error('Insufficient permissions');
    error.statusCode = 403;
    throw error;
  }
}

module.exports = {
  authenticateRequest,
  requireRole,
};
