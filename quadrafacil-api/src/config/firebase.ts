// src/config/firebase.ts

// 1. Importamos 'admin' e também o tipo 'ServiceAccount'
import admin, { ServiceAccount } from 'firebase-admin';

import serviceAccountData from '../../serviceAccountKey.json';

// 2. Fazemos a "afirmação de tipo" para o TypeScript
const serviceAccount = serviceAccountData as ServiceAccount;

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://quadra-facil-app-default-rtdb.firebaseio.com/" 
});

const db = admin.firestore();

export { db };