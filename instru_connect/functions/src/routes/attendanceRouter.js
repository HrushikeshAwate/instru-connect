const { authenticateRequest } = require('../shared/auth');
const {
  badRequest,
  notFound,
  serverError,
  forbidden,
  unauthorized,
} = require('../shared/http');
const sessionController = require('../controllers/sessionController');
const attendanceController = require('../controllers/attendanceController');
const analyticsController = require('../controllers/analyticsController');

const routes = [
  {
    method: 'POST',
    pattern: /^\/sessions$/,
    handler: sessionController.createSession,
  },
  {
    method: 'PATCH',
    pattern: /^\/sessions\/([^/]+)\/close$/,
    handler: sessionController.closeSession,
    params: ['id'],
  },
  {
    method: 'GET',
    pattern: /^\/sessions$/,
    handler: sessionController.listSessions,
  },
  {
    method: 'POST',
    pattern: /^\/attendance\/bulk$/,
    handler: attendanceController.bulkMarkAttendance,
  },
  {
    method: 'GET',
    pattern: /^\/attendance\/student\/([^/]+)$/,
    handler: attendanceController.getStudentAttendance,
    params: ['id'],
  },
  {
    method: 'GET',
    pattern: /^\/attendance\/subject\/([^/]+)\/([^/]+)$/,
    handler: attendanceController.getStudentSubjectAttendance,
    params: ['studentId', 'subjectId'],
  },
  {
    method: 'GET',
    pattern: /^\/attendance\/summary\/([^/]+)$/,
    handler: analyticsController.getStudentSummary,
    params: ['studentId'],
  },
  {
    method: 'GET',
    pattern: /^\/attendance\/defaulters$/,
    handler: analyticsController.getDefaulters,
  },

  // Compatibility routes
  {
    method: 'POST',
    pattern: /^\/sessions\/create$/,
    handler: sessionController.createSession,
  },
  {
    method: 'POST',
    pattern: /^\/attendance\/mark$/,
    handler: attendanceController.bulkMarkAttendance,
  },
  {
    method: 'GET',
    pattern: /^\/sessions\/([^/]+)$/,
    handler: sessionController.listSessions,
    legacySubjectIdParam: true,
  },
];

async function attendanceRouter(req, res) {
  setCors(res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const auth = await authenticateRequest(req);
    const path = normalizePath(req.path || '/');
    const matched = matchRoute(req.method, path);

    if (!matched) {
      notFound(res, 'Route not found');
      return;
    }

    if (matched.legacySubjectId) {
      req.query = {
        ...(req.query || {}),
        subject_id: matched.legacySubjectId,
      };
    }

    await matched.route.handler(req, res, auth, matched.params);
  } catch (error) {
    if (error.statusCode === 400) {
      badRequest(res, error.message);
      return;
    }
    if (error.statusCode === 401) {
      unauthorized(res, error.message);
      return;
    }
    if (error.statusCode === 403) {
      forbidden(res, error.message);
      return;
    }
    if (error.statusCode === 404) {
      notFound(res, error.message);
      return;
    }

    serverError(res, error);
  }
}

function matchRoute(method, path) {
  for (const route of routes) {
    if (route.method !== method) continue;
    const match = path.match(route.pattern);
    if (!match) continue;

    const params = {};
    if (route.params) {
      route.params.forEach((name, index) => {
        params[name] = match[index + 1];
      });
    }

    const legacySubjectId = route.legacySubjectIdParam ? match[1] : null;

    return { route, params, legacySubjectId };
  }
  return null;
}

function normalizePath(path) {
  const normalized = path.replace(/\/+$/, '');
  return normalized || '/';
}

function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type,Authorization');
}

module.exports = {
  attendanceRouter,
};
