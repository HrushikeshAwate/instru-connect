const { admin } = require('./firebase');

function dateKey(date) {
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${date.getUTCFullYear()}-${month}-${day}`;
}

function asTimestamp(value) {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) return value;
  return admin.firestore.Timestamp.fromDate(new Date(value));
}

module.exports = {
  dateKey,
  asTimestamp,
};
