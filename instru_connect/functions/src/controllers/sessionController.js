const attendanceService = require('../services/attendanceService');
const { created, ok } = require('../shared/http');

async function createSession(req, res, auth) {
  const result = await attendanceService.createSession({
    auth,
    payload: req.body || {},
  });
  created(res, result);
}

async function closeSession(req, res, auth, params) {
  const result = await attendanceService.closeSession({
    auth,
    sessionId: params.id,
  });
  ok(res, result);
}

async function listSessions(req, res, auth) {
  const result = await attendanceService.listSessions({
    auth,
    filters: req.query || {},
  });
  ok(res, result);
}

module.exports = {
  createSession,
  closeSession,
  listSessions,
};
