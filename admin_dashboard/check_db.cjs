const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
db.collection('tokens').get().then(snapshot => {
  snapshot.forEach(doc => console.log(doc.id, doc.data()));
  process.exit();
});
