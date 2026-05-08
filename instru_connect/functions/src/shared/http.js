function json(res, statusCode, payload) {
  res.status(statusCode).json(payload);
}

function ok(res, payload) {
  json(res, 200, payload);
}

function created(res, payload) {
  json(res, 201, payload);
}

function badRequest(res, message, details) {
  json(res, 400, { error: message, details });
}

function unauthorized(res, message = 'Unauthorized') {
  json(res, 401, { error: message });
}

function forbidden(res, message = 'Forbidden') {
  json(res, 403, { error: message });
}

function notFound(res, message = 'Not found') {
  json(res, 404, { error: message });
}

function conflict(res, message, details) {
  json(res, 409, { error: message, details });
}

function serverError(res, error) {
  json(res, 500, {
    error: error?.message || 'Internal server error',
  });
}

module.exports = {
  ok,
  created,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
};
