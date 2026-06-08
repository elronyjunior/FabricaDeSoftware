const admin = require('firebase-admin');
const { firebaseServiceAccount } = require('./config/env');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(firebaseServiceAccount),
  });
}

module.exports = admin;
