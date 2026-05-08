const attendanceService = require('../services/attendanceService');
const { ok } = require('../shared/http');

async function getStudentSummary(req, res, auth, params) {
  const result = await attendanceService.getStudentSummary({
    auth,
    studentId: params.studentId,
  });
  ok(res, result);
}

async function getDefaulters(req, res, auth) {
  const result = await attendanceService.getDefaulters({
    auth,
    query: req.query || {},
  });
  ok(res, result);
}

module.exports = {
  getStudentSummary,
  getDefaulters,
};
