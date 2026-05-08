const attendanceService = require('../services/attendanceService');
const { ok } = require('../shared/http');

async function bulkMarkAttendance(req, res, auth) {
  const result = await attendanceService.bulkMarkAttendance({
    auth,
    payload: req.body || {},
  });
  ok(res, result);
}

async function getStudentAttendance(req, res, auth, params) {
  const result = await attendanceService.getStudentAttendance({
    auth,
    studentId: params.id,
    query: req.query || {},
  });
  ok(res, result);
}

async function getStudentSubjectAttendance(req, res, auth, params) {
  const result = await attendanceService.getStudentSubjectAttendance({
    auth,
    studentId: params.studentId,
    subjectId: params.subjectId,
    query: req.query || {},
  });
  ok(res, result);
}

module.exports = {
  bulkMarkAttendance,
  getStudentAttendance,
  getStudentSubjectAttendance,
};
