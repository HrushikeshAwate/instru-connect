const { db } = require('../shared/firebase');

async function listStudentsByBatch(batchId) {
  return db
    .collection('users')
    .where('batchId', '==', batchId)
    .where('role', 'in', ['student', 'cr'])
    .get();
}

module.exports = {
  listStudentsByBatch,
};
