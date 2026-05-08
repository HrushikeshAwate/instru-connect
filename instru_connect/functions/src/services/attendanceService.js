const { db, admin } = require('../shared/firebase');
const { dateKey } = require('../shared/time');
const sessionRepository = require('../repositories/sessionRepository');
const attendanceRepository = require('../repositories/attendanceRepository');
const subjectRepository = require('../repositories/subjectRepository');
const studentRepository = require('../repositories/studentRepository');
const summaryRepository = require('../repositories/summaryRepository');

async function createSession({ auth, payload }) {
  ensureFacultyAccess(auth);
  const required = ['subject_id', 'batch_id', 'date'];
  const missing = required.filter((field) => !payload[field]);
  if (missing.length) {
    const error = new Error(`Missing fields: ${missing.join(', ')}`);
    error.statusCode = 400;
    throw error;
  }

  const subjectSnap = await subjectRepository.getSubjectById(
    String(payload.subject_id),
  );
  if (!subjectSnap.exists) {
    const error = new Error('Subject not found');
    error.statusCode = 404;
    throw error;
  }

  const subject = subjectSnap.data();
  if ((subject.batchId || '') !== String(payload.batch_id)) {
    const error = new Error('Subject does not belong to this batch');
    error.statusCode = 400;
    throw error;
  }

  if (
    auth.role === 'faculty' &&
    subject.facultyId &&
    subject.facultyId !== auth.uid
  ) {
    const error = new Error('Faculty can only create sessions for assigned subjects');
    error.statusCode = 403;
    throw error;
  }

  const sessionId = await sessionRepository.createSession({
    subjectId: String(payload.subject_id),
    facultyId: auth.uid,
    batchId: String(payload.batch_id),
    date: String(payload.date),
    startTime: payload.start_time,
    endTime: payload.end_time,
    status: 'active',
  });

  return { session_id: sessionId };
}

async function closeSession({ auth, sessionId }) {
  ensureFacultyAccess(auth);
  const sessionSnap = await sessionRepository.getSessionById(sessionId);
  if (!sessionSnap.exists) {
    const error = new Error('Session not found');
    error.statusCode = 404;
    throw error;
  }

  const session = sessionSnap.data();
  if (auth.role === 'faculty' && session.facultyId !== auth.uid) {
    const error = new Error('Faculty can only close their own sessions');
    error.statusCode = 403;
    throw error;
  }

  await sessionRepository.closeSession(sessionId);
  return { session_id: sessionId, status: 'closed' };
}

async function listSessions({ auth, filters }) {
  ensureSignedIn(auth);
  const snapshot = await sessionRepository.listSessions({
    subjectId: filters.subject_id,
    batchId: filters.batch_id,
    date: filters.date,
    status: filters.status,
    limit: clampLimit(filters.limit, 100),
    cursor: filters.cursor,
  });

  const items = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...serializeSession(doc.data()),
  }));

  return {
    sessions: items,
    next_cursor: items.length
      ? items[items.length - 1].createdAt || null
      : null,
  };
}

async function bulkMarkAttendance({ auth, payload }) {
  ensureFacultyAccess(auth);

  if (!payload.session_id || !Array.isArray(payload.entries)) {
    const error = new Error('session_id and entries are required');
    error.statusCode = 400;
    throw error;
  }

  const sessionSnap = await sessionRepository.getSessionById(
    String(payload.session_id),
  );
  if (!sessionSnap.exists) {
    const error = new Error('Session not found');
    error.statusCode = 404;
    throw error;
  }

  const session = sessionSnap.data();
  if (session.status === 'closed') {
    const error = new Error('Session is closed');
    error.statusCode = 409;
    throw error;
  }

  if (auth.role === 'faculty' && session.facultyId !== auth.uid) {
    const error = new Error('Faculty can only mark their own sessions');
    error.statusCode = 403;
    throw error;
  }

  const normalizedEntries = normalizeEntries(payload.entries);
  const batchStudentsSnap = await studentRepository.listStudentsByBatch(
    session.batchId,
  );
  const validStudentIds = new Set(batchStudentsSnap.docs.map((doc) => doc.id));

  normalizedEntries.forEach((entry) => {
    if (!validStudentIds.has(entry.studentId)) {
      const error = new Error(`Student ${entry.studentId} does not belong to the batch`);
      error.statusCode = 400;
      throw error;
    }
  });

  const existingAttendanceSnap = await attendanceRepository.listAttendanceBySession(
    String(payload.session_id),
  );
  const existingByStudent = new Map(
    existingAttendanceSnap.docs.map((doc) => [
      doc.data().studentId,
      doc.data().status,
    ]),
  );

  if (isDuplicateSubmission(existingByStudent, normalizedEntries)) {
    return {
      session_id: String(payload.session_id),
      total_students: normalizedEntries.length,
      present_count: normalizedEntries.filter(isCountedPresent).length,
      absent_count: normalizedEntries.filter((entry) => entry.status === 'Absent').length,
      duplicate_submission: true,
    };
  }

  await attendanceRepository.bulkUpsertAttendance({
    session: {
      sessionId: String(payload.session_id),
      subjectId: session.subjectId,
      facultyId: session.facultyId,
      batchId: session.batchId,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
    },
    entries: normalizedEntries,
    markedBy: auth.uid,
  });

  const presentCount = normalizedEntries.filter(isCountedPresent).length;
  const absentEntries = normalizedEntries.filter(
    (entry) => entry.status === 'Absent',
  );

  await db.collection('sessions').doc(String(payload.session_id)).update({
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    totalStudents: normalizedEntries.length,
    presentCount,
    absentCount: absentEntries.length,
    status: payload.auto_close ? 'closed' : session.status,
    lastSubmissionAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await Promise.all(
    normalizedEntries.map((entry) =>
      refreshAttendanceSummary({
        studentId: entry.studentId,
        subjectId: session.subjectId,
        batchId: session.batchId,
      }),
    ),
  );

  await sendAttendanceNotifications({
    subjectId: session.subjectId,
    entries: normalizedEntries,
  });

  return {
    session_id: String(payload.session_id),
    total_students: normalizedEntries.length,
    present_count: presentCount,
    absent_count: absentEntries.length,
    duplicate_submission: false,
  };
}

async function getStudentAttendance({ auth, studentId, query }) {
  ensureStudentViewAccess(auth, studentId);
  const snapshot = await attendanceRepository.listAttendanceByStudent({
    studentId,
    limit: clampLimit(query.limit, 100),
    cursor: query.cursor,
  });

  const records = snapshot.docs.map((doc) => serializeAttendance(doc.data()));
  const presentCount = records.filter((record) => isPresentLike(record.status)).length;

  return {
    student_id: studentId,
    total_sessions: records.length,
    present_count: presentCount,
    attendance_percentage: computePercentage(presentCount, records.length),
    today: records.filter((record) => record.date === dateKey(new Date())),
    last_five_sessions: records.slice(0, 5),
    attendance: records,
    next_cursor: records.length ? records[records.length - 1].markedAt : null,
  };
}

async function getStudentSubjectAttendance({ auth, studentId, subjectId, query }) {
  ensureStudentViewAccess(auth, studentId);
  const snapshot = await attendanceRepository.listAttendanceByStudent({
    studentId,
    subjectId,
    limit: clampLimit(query.limit, 100),
    cursor: query.cursor,
  });

  const records = snapshot.docs.map((doc) => serializeAttendance(doc.data()));
  const presentCount = records.filter((record) => isPresentLike(record.status)).length;

  return {
    student_id: studentId,
    subject_id: subjectId,
    total_sessions: records.length,
    present_count: presentCount,
    attendance_percentage: computePercentage(presentCount, records.length),
    today: records.filter((record) => record.date === dateKey(new Date())),
    last_five_sessions: records.slice(0, 5),
    attendance: records,
    next_cursor: records.length ? records[records.length - 1].markedAt : null,
  };
}

async function getStudentSummary({ auth, studentId }) {
  ensureStudentViewAccess(auth, studentId);

  const summarySnapshot = await db
    .collection('attendance_summary')
    .where('studentId', '==', studentId)
    .get();

  const items = summarySnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  const totalSessions = items.reduce(
    (sum, item) => sum + Number(item.totalSessions || 0),
    0,
  );
  const presentCount = items.reduce(
    (sum, item) => sum + Number(item.presentCount || 0),
    0,
  );

  return {
    student_id: studentId,
    total_sessions: totalSessions,
    present_count: presentCount,
    attendance_percentage: computePercentage(presentCount, totalSessions),
    subjects: items,
  };
}

async function getDefaulters({ auth, query }) {
  requireAdminLikeAccess(auth);
  const threshold = Number(query.threshold || 75);
  const limit = clampLimit(query.limit, 200);
  const snapshot = await db
    .collection('attendance_summary')
    .where('attendancePercentage', '<', threshold)
    .limit(limit)
    .get();

  const items = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  const filtered = items.filter((item) => {
    if (query.subject_id && item.subjectId !== query.subject_id) return false;
    if (query.batch_id && item.batchId !== query.batch_id) return false;
    return true;
  });

  return {
    threshold,
    defaulters: filtered,
  };
}

async function refreshAttendanceSummary({ studentId, subjectId, batchId }) {
  const snapshot = await attendanceRepository.listAttendanceByStudent({
    studentId,
    subjectId,
  });

  const records = snapshot.docs.map((doc) => doc.data());
  const totalSessions = records.length;
  const presentCount = records.filter((record) => isPresentLike(record.status)).length;
  const lateCount = records.filter((record) => record.status === 'Late').length;

  await summaryRepository.upsertSummary({
    studentId,
    subjectId,
    batchId,
    totalSessions,
    presentCount,
    lateCount,
    attendancePercentage: computePercentage(presentCount, totalSessions),
  });
}

async function sendAttendanceNotifications({ subjectId, entries }) {
  const subjectSnap = await subjectRepository.getSubjectById(subjectId);
  const subjectName = (subjectSnap.data()?.name || 'Subject').toString();

  const writer = db.bulkWriter();
  for (const entry of entries) {
    const ref = db.collection('notifications').doc();
    const body = `Marked ${entry.status} for ${subjectName}`;

    writer.set(ref, {
      uid: entry.studentId,
      title: `Attendance marked for ${subjectName}`,
      body,
      type: entry.status === 'Absent' ? 'attendance_absent' : 'attendance_marked',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      data: {
        subjectId,
        subjectName,
        status: entry.status,
      },
      deleteAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      ),
    });
  }
  await writer.close();
}

function normalizeEntries(entries) {
  const seen = new Set();
  return entries.map((entry) => {
    const studentId = String(entry.student_id || entry.studentId || '').trim();
    const rawStatus = String(entry.status || '').trim().toLowerCase();

    if (!studentId || !rawStatus) {
      const error = new Error('Every entry must contain student_id and status');
      error.statusCode = 400;
      throw error;
    }

    if (!['present', 'absent', 'late'].includes(rawStatus)) {
      const error = new Error(`Invalid status for ${studentId}`);
      error.statusCode = 400;
      throw error;
    }

    if (seen.has(studentId)) {
      const error = new Error(`Duplicate student ${studentId} in payload`);
      error.statusCode = 409;
      throw error;
    }
    seen.add(studentId);

    return {
      studentId,
      status: capitalizeStatus(rawStatus),
    };
  });
}

function isDuplicateSubmission(existingByStudent, entries) {
  if (existingByStudent.size !== entries.length) return false;
  return entries.every((entry) => existingByStudent.get(entry.studentId) === entry.status);
}

function isCountedPresent(entry) {
  return isPresentLike(entry.status);
}

function isPresentLike(status) {
  return status === 'Present' || status === 'Late';
}

function computePercentage(presentCount, totalSessions) {
  if (!totalSessions) return 0;
  return Number(((presentCount / totalSessions) * 100).toFixed(2));
}

function capitalizeStatus(status) {
  return status.charAt(0).toUpperCase() + status.slice(1);
}

function serializeSession(session) {
  return {
    session_id: session.sessionId,
    subject_id: session.subjectId,
    faculty_id: session.facultyId,
    batch_id: session.batchId,
    date: session.date,
    start_time: session.startTime?.toDate?.().toISOString?.() || null,
    end_time: session.endTime?.toDate?.().toISOString?.() || null,
    status: session.status,
    createdAt: session.createdAt?.toDate?.().toISOString?.() || null,
  };
}

function serializeAttendance(record) {
  return {
    attendance_id: record.attendanceId,
    session_id: record.sessionId,
    student_id: record.studentId,
    subject_id: record.subjectId,
    status: record.status,
    markedAt: record.markedAt?.toDate?.().toISOString?.() || null,
    date: record.date,
  };
}

function clampLimit(value, max) {
  const parsed = Number(value || 50);
  if (!Number.isFinite(parsed) || parsed <= 0) return 50;
  return Math.min(parsed, max);
}

function ensureSignedIn(auth) {
  if (!auth?.uid) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }
}

function ensureFacultyAccess(auth) {
  ensureSignedIn(auth);
  if (!['faculty', 'admin'].includes(auth.role)) {
    const error = new Error('Only faculty can manage attendance');
    error.statusCode = 403;
    throw error;
  }
}

function requireAdminLikeAccess(auth) {
  ensureSignedIn(auth);
  if (!['faculty', 'admin'].includes(auth.role)) {
    const error = new Error('Only faculty or admin can view analytics');
    error.statusCode = 403;
    throw error;
  }
}

function ensureStudentViewAccess(auth, studentId) {
  ensureSignedIn(auth);
  if (['faculty', 'admin'].includes(auth.role)) {
    return;
  }

  if (auth.uid !== studentId) {
    const error = new Error('Students can only view their own attendance');
    error.statusCode = 403;
    throw error;
  }
}

module.exports = {
  createSession,
  closeSession,
  listSessions,
  bulkMarkAttendance,
  getStudentAttendance,
  getStudentSubjectAttendance,
  getStudentSummary,
  getDefaulters,
};
