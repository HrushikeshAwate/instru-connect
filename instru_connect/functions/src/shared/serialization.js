const { admin } = require('./firebase');

function serializeValue(value) {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate().toISOString();
  }

  if (Array.isArray(value)) {
    return value.map(serializeValue);
  }

  if (value && typeof value === 'object') {
    return serializeDocument(value);
  }

  return value;
}

function serializeDocument(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, serializeValue(value)]),
  );
}

module.exports = {
  serializeDocument,
  serializeValue,
};
