const { db } = require('../shared/firebase');

async function getSubjectById(subjectId) {
  return db.collection('subjects').doc(subjectId).get();
}

module.exports = {
  getSubjectById,
};
